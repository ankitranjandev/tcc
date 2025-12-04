import dotenv from 'dotenv';

dotenv.config();

interface Config {
  env: string;
  port: number;
  apiVersion: string;
  baseUrl: string;
  database: {
    host: string;
    port: number;
    name: string;
    user: string;
    password: string;
    ssl: boolean;
    poolMin: number;
    poolMax: number;
  };
  jwt: {
    secret: string;
    expiresIn: string;
    refreshSecret: string;
    refreshExpiresIn: string;
  };
  bcrypt: {
    rounds: number;
  };
  rateLimit: {
    windowMs: number;
    maxRequests: number;
    authMaxRequests: number;
  };
  fileUpload: {
    maxSize: number;
    uploadDir: string;
    allowedTypes: string[];
  };
  email: {
    host: string;
    port: number;
    user: string;
    password: string;
    from: string;
  };
  sms: {
    apiKey: string;
    apiUrl: string;
  };
  logging: {
    level: string;
    file: string;
  };
  cors: {
    origin: string[];
  };
  websocket: {
    port: number;
    path: string;
  };
  security: {
    sessionTimeoutMinutes: number;
    maxLoginAttempts: number;
    accountLockoutMinutes: number;
    passwordMinLength: number;
    otpExpiryMinutes: number;
    otpLength: number;
  };
  limits: {
    minDepositAmount: number;
    maxDepositAmount: number;
    minWithdrawalAmount: number;
    maxWithdrawalAmount: number;
    minTransferAmount: number;
    maxTransferAmount: number;
  };
  fees: {
    depositFeePercent: number;
    withdrawalFeePercent: number;
    transferFeePercent: number;
  };
  agent: {
    baseCommissionRate: number;
  };
}

const config: Config = {
  env: process.env.NODE_ENV || 'development',
  port: parseInt(process.env.PORT || '3000', 10),
  apiVersion: process.env.API_VERSION || 'v1',
  baseUrl: process.env.BASE_URL || 'http://localhost:3000',

  database: {
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT || '5432', 10),
    name: process.env.DB_NAME || 'tcc_database',
    user: process.env.DB_USER || 'postgres',
    password: process.env.DB_PASSWORD || '',
    ssl: process.env.DB_SSL === 'true',
    poolMin: parseInt(process.env.DB_POOL_MIN || '2', 10),
    poolMax: parseInt(process.env.DB_POOL_MAX || '10', 10),
  },

  jwt: {
    secret: process.env.JWT_SECRET || 'your-super-secret-jwt-key',
    expiresIn: process.env.JWT_EXPIRES_IN || '1h',
    refreshSecret: process.env.JWT_REFRESH_SECRET || 'your-super-secret-refresh-key',
    refreshExpiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '7d',
  },

  bcrypt: {
    rounds: parseInt(process.env.BCRYPT_ROUNDS || '10', 10),
  },

  rateLimit: {
    windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS || '60000', 10),
    maxRequests: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS || '100', 10),
    authMaxRequests: parseInt(process.env.AUTH_RATE_LIMIT_MAX || '5', 10),
  },

  fileUpload: {
    maxSize: parseInt(process.env.MAX_FILE_SIZE || '10485760', 10),
    uploadDir: process.env.UPLOAD_DIR || 'uploads',
    allowedTypes: (process.env.ALLOWED_FILE_TYPES || 'image/jpeg,image/png,application/pdf').split(
      ','
    ),
  },

  email: {
    host: process.env.SMTP_HOST || 'smtp.gmail.com',
    port: parseInt(process.env.SMTP_PORT || '587', 10),
    user: process.env.SMTP_USER || '',
    password: process.env.SMTP_PASSWORD || '',
    from: process.env.SMTP_FROM || 'noreply@tccapp.com',
  },

  sms: {
    apiKey: process.env.SMS_API_KEY || '',
    apiUrl: process.env.SMS_API_URL || '',
  },

  logging: {
    level: process.env.LOG_LEVEL || 'info',
    file: process.env.LOG_FILE || 'logs/app.log',
  },

  cors: {
    origin: (process.env.CORS_ORIGIN || 'http://localhost:3000').split(','),
  },

  websocket: {
    port: parseInt(process.env.WS_PORT || '3001', 10),
    path: process.env.WS_PATH || '/socket.io',
  },

  security: {
    sessionTimeoutMinutes: parseInt(process.env.SESSION_TIMEOUT_MINUTES || '30', 10),
    maxLoginAttempts: parseInt(process.env.MAX_LOGIN_ATTEMPTS || '5', 10),
    accountLockoutMinutes: parseInt(process.env.ACCOUNT_LOCKOUT_MINUTES || '30', 10),
    passwordMinLength: parseInt(process.env.PASSWORD_MIN_LENGTH || '8', 10),
    otpExpiryMinutes: parseInt(process.env.OTP_EXPIRY_MINUTES || '5', 10),
    otpLength: parseInt(process.env.OTP_LENGTH || '6', 10),
  },

  limits: {
    minDepositAmount: parseInt(process.env.MIN_DEPOSIT_AMOUNT || '1000', 10),
    maxDepositAmount: parseInt(process.env.MAX_DEPOSIT_AMOUNT || '10000000', 10),
    minWithdrawalAmount: parseInt(process.env.MIN_WITHDRAWAL_AMOUNT || '1000', 10),
    maxWithdrawalAmount: parseInt(process.env.MAX_WITHDRAWAL_AMOUNT || '5000000', 10),
    minTransferAmount: parseInt(process.env.MIN_TRANSFER_AMOUNT || '100', 10),
    maxTransferAmount: parseInt(process.env.MAX_TRANSFER_AMOUNT || '2000000', 10),
  },

  fees: {
    depositFeePercent: parseFloat(process.env.DEPOSIT_FEE_PERCENT || '0'),
    withdrawalFeePercent: parseFloat(process.env.WITHDRAWAL_FEE_PERCENT || '2'),
    transferFeePercent: parseFloat(process.env.TRANSFER_FEE_PERCENT || '1'),
  },

  agent: {
    baseCommissionRate: parseFloat(process.env.AGENT_BASE_COMMISSION_RATE || '0.5'),
  },
};

export default config;
