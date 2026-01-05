import express, { Application } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import compression from 'compression';
import swaggerUi from 'swagger-ui-express';
import path from 'path';
import config from './config';
import logger from './utils/logger';
import { errorHandler, notFoundHandler } from './middleware/errorHandler';
import { generalRateLimiter } from './middleware/rateLimit';
import { swaggerSpec } from './config/swagger';

class App {
  public app: Application;
  private initialized: Promise<void>;

  constructor() {
    this.app = express();
    this.initializeMiddleware();
    this.initialized = this.initialize();
  }

  private async initialize(): Promise<void> {
    await this.initializeRoutes();
    this.initializeErrorHandling();
  }

  public async waitForInitialization(): Promise<void> {
    await this.initialized;
  }

  private initializeMiddleware(): void {
    // Security middleware
    this.app.use(helmet());

    // CORS configuration
    const allowedOrigins = [
      'https://tcc-app-ebb14.web.app',
      'https://tcc-app-ebb14.firebaseapp.com',
      'https://dppyssab6rrh5.cloudfront.net',
      'http://localhost:3000',
      'http://localhost:8080',
      'http://localhost:5000',
    ];

    this.app.use(
      cors({
        origin: (origin, callback) => {
          // Allow requests with no origin (mobile apps, curl, etc.)
          if (!origin) return callback(null, true);

          if (allowedOrigins.includes(origin)) {
            callback(null, true);
          } else {
            // Log unauthorized origin attempts but still allow for now
            logger.warn('CORS request from unauthorized origin', { origin });
            callback(null, true); // Allow all origins in development; set to false in strict production
          }
        },
        credentials: true,
        methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
        allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With', 'Accept'],
      })
    );

    // Stripe webhook route (must be before body parsing middleware)
    // Webhook route needs raw body for signature verification
    this.app.post(
      '/webhooks/stripe',
      express.raw({ type: 'application/json' }),
      async (req, res, next) => {
        try {
          const { WebhookController } = await import('./controllers/webhook.controller');
          return WebhookController.handleStripeWebhook(req, res);
        } catch (error) {
          next(error);
        }
      }
    );

    // Body parsing middleware (applied after webhook route)
    this.app.use(express.json({ limit: '10mb' }));
    this.app.use(express.urlencoded({ extended: true, limit: '10mb' }));

    // Compression middleware
    this.app.use(compression());

    // Rate limiting
    this.app.use(generalRateLimiter);

    // Serve static files for exports
    this.app.use('/uploads/exports', express.static(path.join(__dirname, '../uploads/exports')));
    logger.info('Static file serving enabled for exports');

    // Request logging middleware
    this.app.use((req, res, next) => {
      const start = Date.now();
      
      // Log request details for debugging uploads
      if (req.path.includes('upload') || (req.method === 'POST' && req.path === '/')) {
        logger.info('Incoming request details', {
          method: req.method,
          originalUrl: req.originalUrl,
          path: req.path,
          baseUrl: req.baseUrl,
          url: req.url,
          headers: {
            'content-type': req.headers['content-type'],
            'authorization': req.headers['authorization'] ? 'Bearer ***' : 'None'
          }
        });
      }
      
      res.on('finish', () => {
        const duration = Date.now() - start;
        logger.info('HTTP Request', {
          method: req.method,
          path: req.path,
          status: res.statusCode,
          duration: `${duration}ms`,
          ip: req.ip,
        });
      });
      next();
    });

    logger.info('Middleware initialized');
  }

  private async initializeRoutes(): Promise<void> {
    // Health check endpoint
    this.app.get('/health', (_req, res) => {
      res.status(200).json({
        success: true,
        data: {
          status: 'healthy',
          timestamp: new Date().toISOString(),
          uptime: process.uptime(),
          environment: config.env,
        },
      });
    });

    // API version endpoint
    this.app.get(`/${config.apiVersion}`, (_req, res) => {
      res.status(200).json({
        success: true,
        data: {
          version: config.apiVersion,
          name: 'TCC Backend API',
          description: 'Financial services platform for African markets',
        },
      });
    });

    // API Documentation
    this.app.use(
      `/${config.apiVersion}/docs`,
      swaggerUi.serve,
      swaggerUi.setup(swaggerSpec, {
        customCss: '.swagger-ui .topbar { display: none }',
        customSiteTitle: 'TCC API Documentation',
      })
    );
    logger.info('API documentation registered at', { path: `/${config.apiVersion}/docs` });

    // Import and register route modules
    const apiPrefix = `/${config.apiVersion}`;

    // Authentication routes
    const authRoutes = await import('./routes/auth.routes');
    this.app.use(`${apiPrefix}/auth`, authRoutes.default);
    logger.info('Auth routes registered');

    // User routes
    const userRoutes = await import('./routes/user.routes');
    this.app.use(`${apiPrefix}/users`, userRoutes.default);
    this.app.use(`${apiPrefix}/user`, userRoutes.default); // Alias for singular
    logger.info('User routes registered');

    // Wallet routes
    const walletRoutes = await import('./routes/wallet.routes');
    this.app.use(`${apiPrefix}/wallet`, walletRoutes.default);
    logger.info('Wallet routes registered');

    // Transaction routes
    const transactionRoutes = await import('./routes/transaction.routes');
    this.app.use(`${apiPrefix}/transactions`, transactionRoutes.default);
    logger.info('Transaction routes registered');

    // KYC routes
    const kycRoutes = await import('./routes/kyc.routes');
    this.app.use(`${apiPrefix}/kyc`, kycRoutes.default);
    logger.info('KYC routes registered');

    // Investment routes
    const investmentRoutes = await import('./routes/investment.routes');
    this.app.use(`${apiPrefix}/investments`, investmentRoutes.default);
    logger.info('Investment routes registered');

    // Agent routes
    const agentRoutes = await import('./routes/agent.routes');
    this.app.use(`${apiPrefix}/agent`, agentRoutes.default);
    logger.info('Agent routes registered');

    // Admin routes
    const adminRoutes = await import('./routes/admin.routes');
    logger.info('Admin routes module loaded', { hasDefault: !!adminRoutes.default, keys: Object.keys(adminRoutes) });
    this.app.use(`${apiPrefix}/admin`, adminRoutes.default);
    logger.info('Admin routes registered at path', { path: `${apiPrefix}/admin` });

    // Bill payment routes
    const billRoutes = await import('./routes/bill.routes');
    this.app.use(`${apiPrefix}/bills`, billRoutes.default);
    logger.info('Bill routes registered');

    // Poll/Voting routes
    const pollRoutes = await import('./routes/poll.routes');
    this.app.use(`${apiPrefix}/polls`, pollRoutes.default);
    logger.info('Poll routes registered');

    // Election/E-Voting routes
    const electionRoutes = await import('./routes/election.routes');
    this.app.use(`${apiPrefix}`, electionRoutes.default);
    logger.info('Election routes registered');

    // Upload routes
    const uploadRoutes = await import('./routes/upload.routes');
    this.app.use(`${apiPrefix}/uploads`, uploadRoutes.default);
    logger.info('Upload routes registered at', { path: `${apiPrefix}/uploads` });

    // Bank account routes
    const bankAccountRoutes = await import('./routes/bank-account.routes');
    this.app.use(`${apiPrefix}/bank-accounts`, bankAccountRoutes.default);
    logger.info('Bank account routes registered');

    // Market data routes (metal prices, currency rates)
    const marketRoutes = await import('./routes/market.routes');
    this.app.use(`${apiPrefix}/market`, marketRoutes.default);
    logger.info('Market routes registered');

    // Currency investment routes
    const currencyInvestmentRoutes = await import('./routes/currency-investment.routes');
    this.app.use(`${apiPrefix}/currency-investments`, currencyInvestmentRoutes.default);
    logger.info('Currency investment routes registered');

    logger.info('Routes initialized');

    // Debug: Log all registered routes
    logger.info('=== Registered Routes ===');
    this.app._router.stack.forEach((middleware: any) => {
      if (middleware.route) {
        // Routes registered directly on the app
        logger.info(`${Object.keys(middleware.route.methods)} ${middleware.route.path}`);
      } else if (middleware.name === 'router') {
        // Router middleware
        logger.info(`Router: ${middleware.regexp}`);
        middleware.handle.stack.forEach((handler: any) => {
          if (handler.route) {
            const route = handler.route;
            logger.info(`  ${Object.keys(route.methods).join(',')} ${route.path}`);
          }
        });
      }
    });
    logger.info('=== End Routes ===');
  }

  private initializeErrorHandling(): void {
    // 404 handler
    this.app.use(notFoundHandler);

    // Global error handler
    this.app.use(errorHandler);

    logger.info('Error handling initialized');
  }

  public getApp(): Application {
    return this.app;
  }
}

const appInstance = new App();
export const waitForAppInitialization = () => appInstance.waitForInitialization();
export default appInstance.getApp();
