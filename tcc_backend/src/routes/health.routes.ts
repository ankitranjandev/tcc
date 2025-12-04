import { Router } from 'express';
import database from '../database';
import { ApiResponseUtil } from '../utils/response';

const router = Router();

router.get('/', async (req, res) => {
  try {
    const dbHealthy = await database.testConnection();

    res.status(200).json({
      success: true,
      data: {
        status: dbHealthy ? 'healthy' : 'degraded',
        timestamp: new Date().toISOString(),
        uptime: process.uptime(),
        database: dbHealthy ? 'connected' : 'disconnected',
        memory: {
          used: Math.round(process.memoryUsage().heapUsed / 1024 / 1024),
          total: Math.round(process.memoryUsage().heapTotal / 1024 / 1024),
        },
      },
    });
  } catch (error) {
    return ApiResponseUtil.internalError(res, 'Health check failed');
  }
});

export default router;
