import { Response } from 'express';
import { AuthRequest } from '../types';
import { BillService } from '../services/bill.service';
import { ApiResponseUtil } from '../utils/response';
import logger from '../utils/logger';

export class BillController {
  /**
   * Get bill providers by category
   */
  static async getProviders(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const { category } = req.query;

      const providers = await BillService.getProviders(category as any);

      return ApiResponseUtil.success(res, {
        providers,
        total: providers.length,
      });
    } catch (error: any) {
      logger.error('Get bill providers error', error);
      return ApiResponseUtil.internalError(res);
    }
  }

  /**
   * Fetch bill details before payment
   */
  static async fetchBillDetails(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const { provider_id, account_number } = req.body;

      const billDetails = await BillService.fetchBillDetails(provider_id, account_number);

      return ApiResponseUtil.success(
        res,
        { bill_details: billDetails },
        'Bill details fetched successfully'
      );
    } catch (error: any) {
      logger.error('Fetch bill details error', error);

      if (error.message === 'PROVIDER_NOT_FOUND') {
        return ApiResponseUtil.notFound(res, 'Bill provider not found');
      }

      return ApiResponseUtil.internalError(res);
    }
  }

  /**
   * Request OTP for bill payment
   */
  static async requestPaymentOTP(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const userId = req.user?.id;

      if (!userId) {
        return ApiResponseUtil.unauthorized(res);
      }

      const result = await BillService.requestBillPaymentOTP(userId);

      return ApiResponseUtil.success(
        res,
        {
          otp_sent: result.otpSent,
          phone: result.phone,
          otp_expires_in: result.otpExpiresIn,
        },
        'OTP sent to your registered phone number'
      );
    } catch (error: any) {
      logger.error('Request bill payment OTP error', error);

      if (error.message === 'USER_NOT_FOUND') {
        return ApiResponseUtil.notFound(res, 'User not found');
      }

      return ApiResponseUtil.internalError(res);
    }
  }

  /**
   * Create Stripe payment intent for bill payment
   */
  static async createPaymentIntent(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const userId = req.user?.id;

      if (!userId) {
        return ApiResponseUtil.unauthorized(res);
      }

      const { provider_id, account_number, amount, metadata } = req.body;

      const result = await BillService.createPaymentIntent(
        userId,
        provider_id,
        account_number,
        amount,
        metadata
      );

      return ApiResponseUtil.success(
        res,
        result,
        'Payment intent created successfully'
      );
    } catch (error: any) {
      logger.error('Create bill payment intent error', error);

      if (error.message === 'INVALID_AMOUNT') {
        return ApiResponseUtil.badRequest(res, 'Invalid amount');
      }

      if (error.message === 'USER_NOT_FOUND') {
        return ApiResponseUtil.notFound(res, 'User not found');
      }

      if (error.message === 'PROVIDER_NOT_FOUND') {
        return ApiResponseUtil.notFound(res, 'Bill provider not found');
      }

      if (error.message.includes('STRIPE')) {
        return ApiResponseUtil.badRequest(res, 'Payment processing error. Please try again.');
      }

      return ApiResponseUtil.internalError(res);
    }
  }

  /**
   * Pay bill
   */
  static async payBill(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const userId = req.user?.id;

      if (!userId) {
        return ApiResponseUtil.unauthorized(res);
      }

      const { provider_id, account_number, amount, otp, metadata } = req.body;

      const result = await BillService.payBill(
        userId,
        provider_id,
        account_number,
        amount,
        otp,
        metadata
      );

      return ApiResponseUtil.created(
        res,
        {
          payment: result,
        },
        'Bill payment completed successfully'
      );
    } catch (error: any) {
      logger.error('Bill payment error', error);

      if (error.message === 'INVALID_AMOUNT') {
        return ApiResponseUtil.badRequest(res, 'Invalid amount');
      }

      if (error.message === 'USER_NOT_FOUND') {
        return ApiResponseUtil.notFound(res, 'User not found');
      }

      if (error.message === 'PROVIDER_NOT_FOUND') {
        return ApiResponseUtil.notFound(res, 'Bill provider not found');
      }

      if (error.message === 'INVALID_OTP' || error.message.includes('OTP')) {
        return ApiResponseUtil.badRequest(res, error.message);
      }

      if (error.message === 'INSUFFICIENT_BALANCE') {
        return ApiResponseUtil.badRequest(res, 'Insufficient balance in wallet');
      }

      return ApiResponseUtil.internalError(res);
    }
  }

  /**
   * Get bill payment history
   */
  static async getBillHistory(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const userId = req.user?.id;

      if (!userId) {
        return ApiResponseUtil.unauthorized(res);
      }

      const { bill_type, status, from_date, to_date, search, page = 1, limit = 20 } = req.query;

      // Prepare filters
      const filters: any = {};
      if (bill_type) filters.bill_type = bill_type;
      if (status) filters.status = status;
      if (from_date) filters.fromDate = new Date(from_date as string);
      if (to_date) filters.toDate = new Date(to_date as string);
      if (search) filters.search = search;

      // Prepare pagination
      const pageNum = parseInt(page as string) || 1;
      const limitNum = parseInt(limit as string) || 20;
      const pagination = {
        page: pageNum,
        limit: limitNum,
        offset: (pageNum - 1) * limitNum,
      };

      const result = await BillService.getBillHistory(userId, filters, pagination);

      return ApiResponseUtil.success(
        res,
        {
          payments: result.payments,
        },
        undefined,
        {
          pagination: result.pagination,
        }
      );
    } catch (error: any) {
      logger.error('Get bill history error', error);
      return ApiResponseUtil.internalError(res);
    }
  }
}
