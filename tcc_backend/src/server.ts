import app, { waitForAppInitialization } from './app';
import config from './config';
import logger from './utils/logger';
import database from './database';

const startServer = async () => {
  try {
    // Wait for app initialization (routes loading)
    await waitForAppInitialization();

    // Test database connection
    logger.info('Testing database connection...');
    const dbConnected = await database.testConnection();

    if (!dbConnected) {
      logger.error('Failed to connect to database');
      process.exit(1);
    }

    // Start HTTP server
    const server = app.listen(config.port, () => {
      logger.info(`Server started successfully`, {
        port: config.port,
        environment: config.env,
        apiVersion: config.apiVersion,
        baseUrl: config.baseUrl,
      });
      logger.info(`Health check available at: ${config.baseUrl}/health`);
      logger.info(`API documentation (coming soon): ${config.baseUrl}/${config.apiVersion}/docs`);
    });

    // Graceful shutdown
    const gracefulShutdown = async (signal: string) => {
      logger.info(`${signal} received. Starting graceful shutdown...`);

      server.close(async () => {
        logger.info('HTTP server closed');

        try {
          await database.close();
          logger.info('Database connections closed');
          process.exit(0);
        } catch (error) {
          logger.error('Error during graceful shutdown', error);
          process.exit(1);
        }
      });

      // Force shutdown after 10 seconds
      setTimeout(() => {
        logger.error('Forced shutdown after timeout');
        process.exit(1);
      }, 10000);
    };

    // Listen for termination signals
    process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
    process.on('SIGINT', () => gracefulShutdown('SIGINT'));

    // Handle uncaught exceptions
    process.on('uncaughtException', (error) => {
      logger.error('Uncaught Exception', error);
      gracefulShutdown('uncaughtException');
    });

    // Handle unhandled promise rejections
    process.on('unhandledRejection', (reason, promise) => {
      logger.error('Unhandled Rejection', { reason, promise });
      gracefulShutdown('unhandledRejection');
    });
  } catch (error) {
    logger.error('Failed to start server', error);
    process.exit(1);
  }
};

startServer();
