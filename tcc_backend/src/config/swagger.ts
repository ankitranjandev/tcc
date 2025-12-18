import swaggerJsdoc from 'swagger-jsdoc';
import { Options } from 'swagger-jsdoc';
import config from './index';

const swaggerOptions: Options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'TCC Backend API',
      version: '1.0.0',
      description: 'Financial services platform for African markets - Complete API documentation',
      contact: {
        name: 'TCC Team',
        email: 'support@tccapp.com',
      },
      license: {
        name: 'MIT',
        url: 'https://opensource.org/licenses/MIT',
      },
    },
    servers: [
      {
        url: `${config.baseUrl}/${config.apiVersion}`,
        description: config.env === 'production' ? 'Production server' : 'Development server',
      },
    ],
    components: {
      securitySchemes: {
        bearerAuth: {
          type: 'http',
          scheme: 'bearer',
          bearerFormat: 'JWT',
          description: 'Enter your JWT token',
        },
      },
      schemas: {
        Error: {
          type: 'object',
          properties: {
            success: {
              type: 'boolean',
              example: false,
            },
            error: {
              type: 'object',
              properties: {
                message: {
                  type: 'string',
                  example: 'An error occurred',
                },
                code: {
                  type: 'string',
                  example: 'ERROR_CODE',
                },
              },
            },
          },
        },
        SuccessResponse: {
          type: 'object',
          properties: {
            success: {
              type: 'boolean',
              example: true,
            },
            data: {
              type: 'object',
            },
            message: {
              type: 'string',
            },
          },
        },
      },
    },
    security: [
      {
        bearerAuth: [],
      },
    ],
    tags: [
      {
        name: 'Authentication',
        description: 'User authentication and authorization endpoints',
      },
      {
        name: 'Users',
        description: 'User management endpoints',
      },
      {
        name: 'Wallet',
        description: 'Wallet and balance management endpoints',
      },
      {
        name: 'Transactions',
        description: 'Transaction history and management endpoints',
      },
      {
        name: 'KYC',
        description: 'Know Your Customer verification endpoints',
      },
      {
        name: 'Investments',
        description: 'Investment products and portfolio management endpoints',
      },
      {
        name: 'Agent',
        description: 'Agent operations and commission endpoints',
      },
      {
        name: 'Admin',
        description: 'Administrative endpoints',
      },
      {
        name: 'Bills',
        description: 'Bill payment endpoints',
      },
      {
        name: 'Polls',
        description: 'Poll and voting endpoints',
      },
    ],
  },
  apis: ['./src/routes/*.ts'], // Path to the API routes files
};

export const swaggerSpec = swaggerJsdoc(swaggerOptions);
