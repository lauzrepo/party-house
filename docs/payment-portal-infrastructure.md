# Payment Portal Infrastructure Documentation

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [Technology Stack](#technology-stack)
- [Database Schema](#database-schema)
- [API Endpoints](#api-endpoints)
- [Helcim Integration](#helcim-integration)
- [Security Implementation](#security-implementation)
- [Deployment Strategy](#deployment-strategy)
- [Monitoring & Logging](#monitoring--logging)
- [Backup & Recovery](#backup--recovery)
- [Performance Optimization](#performance-optimization)

---

## Architecture Overview

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         Client Layer                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   Browser    │  │    Mobile    │  │   Desktop    │      │
│  │  (React SPA) │  │     PWA      │  │     App      │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└───────────────────────────┬─────────────────────────────────┘
                            │ HTTPS
                            │
┌───────────────────────────▼─────────────────────────────────┐
│                      CDN / Edge Cache                        │
│                    (Vercel Edge Network)                     │
└───────────────────────────┬─────────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────────┐
│                    Frontend (Vercel)                         │
│  ┌────────────────────────────────────────────────────┐     │
│  │  Static React App (SPA)                            │     │
│  │  - Vite build                                      │     │
│  │  - Helcim.js (payment tokenization)                │     │
│  │  - React Router (client-side routing)              │     │
│  └────────────────────────────────────────────────────┘     │
└───────────────────────────┬─────────────────────────────────┘
                            │ REST API / HTTPS
                            │
┌───────────────────────────▼─────────────────────────────────┐
│                  API Gateway / Load Balancer                 │
│                      (Railway/Render)                        │
└───────────────────────────┬─────────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────────┐
│                    Backend API (Node.js)                     │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ Express.js   │  │ Middleware   │  │  Controllers │      │
│  │   Server     │  │   Layer      │  │              │      │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘      │
│         │                  │                  │              │
│  ┌──────▼──────────────────▼──────────────────▼───────┐     │
│  │             Service Layer                          │     │
│  │  - Helcim Service  - Email Service                │     │
│  │  - Auth Service    - PDF Service                  │     │
│  └────────────────────────┬───────────────────────────┘     │
└────────────────────────────┼─────────────────────────────────┘
                             │
        ┌────────────────────┼────────────────────┐
        │                    │                    │
┌───────▼──────┐  ┌──────────▼────────┐  ┌───────▼──────┐
│  PostgreSQL  │  │   Helcim API      │  │   AWS S3     │
│   Database   │  │ (Payment Gateway) │  │ (File Store) │
└──────────────┘  └───────────────────┘  └──────────────┘
        │
┌───────▼──────┐
│ Redis Cache  │
│  (Optional)  │
└──────────────┘
```

### Component Interaction Flow

**Payment Processing Flow:**
```
User → Frontend → Helcim.js (tokenize card) → Frontend (get token)
     → Backend API → Validate → Helcim API → Process Payment
     → Backend API → Update DB → Return Response → Frontend → User
```

**Webhook Flow:**
```
Helcim Event → Helcim Server → Webhook Endpoint (Backend)
            → Verify Signature → Process Event → Update DB
            → Send Notification → Log Event
```

---

## Technology Stack

### Frontend Stack

#### Core Framework
```json
{
  "react": "^18.2.0",
  "react-dom": "^18.2.0",
  "react-router-dom": "^6.14.0",
  "typescript": "^5.0.0",
  "vite": "^4.4.0"
}
```

#### UI & Styling
```json
{
  "@mui/material": "^5.14.0",
  "@mui/icons-material": "^5.14.0",
  "@emotion/react": "^11.11.0",
  "@emotion/styled": "^11.11.0",
  "tailwindcss": "^3.3.0"
}
```

#### State Management & Data Fetching
```json
{
  "@tanstack/react-query": "^4.32.0",
  "axios": "^1.4.0",
  "zustand": "^4.4.0"
}
```

#### Forms & Validation
```json
{
  "react-hook-form": "^7.45.0",
  "zod": "^3.21.0",
  "@hookform/resolvers": "^3.1.0"
}
```

#### Payment Integration
```json
{
  "helcim-js": "^1.0.0"  // Loaded via CDN
}
```

### Backend Stack

#### Core Framework
```json
{
  "express": "^4.18.0",
  "typescript": "^5.0.0",
  "ts-node": "^10.9.0",
  "nodemon": "^3.0.0"
}
```

#### Database & ORM
```json
{
  "@prisma/client": "^5.0.0",
  "prisma": "^5.0.0",
  "pg": "^8.11.0"
}
```

#### Authentication & Security
```json
{
  "jsonwebtoken": "^9.0.0",
  "bcrypt": "^5.1.0",
  "helmet": "^7.0.0",
  "cors": "^2.8.0",
  "express-rate-limit": "^6.8.0",
  "express-validator": "^7.0.0"
}
```

#### Utilities
```json
{
  "axios": "^1.4.0",
  "dotenv": "^16.3.0",
  "winston": "^3.10.0",
  "joi": "^17.9.0",
  "pdfkit": "^0.13.0",
  "nodemailer": "^6.9.0"
}
```

---

## Database Schema

### Complete Prisma Schema

```prisma
// prisma/schema.prisma

generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

// User model
model User {
  id                  String    @id @default(uuid())
  email               String    @unique
  passwordHash        String    @map("password_hash")
  firstName           String?   @map("first_name")
  lastName            String?   @map("last_name")
  helcimCustomerId    String?   @unique @map("helcim_customer_id")
  createdAt           DateTime  @default(now()) @map("created_at")
  updatedAt           DateTime  @updatedAt @map("updated_at")
  deletedAt           DateTime? @map("deleted_at")
  gdprConsent         Boolean   @default(false) @map("gdpr_consent")
  gdprConsentDate     DateTime? @map("gdpr_consent_date")

  // Relations
  payments            Payment[]
  subscriptions       Subscription[]
  invoices            Invoice[]
  paymentMethods      PaymentMethod[]
  auditLogs           AuditLog[]

  @@map("users")
}

// Payment model
model Payment {
  id                    String   @id @default(uuid())
  userId                String   @map("user_id")
  helcimTransactionId   String?  @unique @map("helcim_transaction_id")
  amount                Decimal  @db.Decimal(10, 2)
  currency              String   @default("USD")
  status                String
  paymentMethodType     String   @map("payment_method_type")
  cardToken             String?  @map("card_token")
  description           String?
  metadata              Json?
  createdAt             DateTime @default(now()) @map("created_at")
  updatedAt             DateTime @updatedAt @map("updated_at")

  // Relations
  user                  User     @relation(fields: [userId], references: [id])

  @@map("payments")
  @@index([userId])
  @@index([status])
  @@index([createdAt])
}

// Subscription model
model Subscription {
  id                    String    @id @default(uuid())
  userId                String    @map("user_id")
  helcimSubscriptionId  String?   @unique @map("helcim_subscription_id")
  planName              String    @map("plan_name")
  planAmount            Decimal   @map("plan_amount") @db.Decimal(10, 2)
  billingFrequency      String    @map("billing_frequency")
  status                String
  currentPeriodStart    DateTime  @map("current_period_start")
  currentPeriodEnd      DateTime  @map("current_period_end")
  nextBillingDate       DateTime? @map("next_billing_date")
  cancelAtPeriodEnd     Boolean   @default(false) @map("cancel_at_period_end")
  createdAt             DateTime  @default(now()) @map("created_at")
  updatedAt             DateTime  @updatedAt @map("updated_at")
  canceledAt            DateTime? @map("canceled_at")

  // Relations
  user                  User      @relation(fields: [userId], references: [id])

  @@map("subscriptions")
  @@index([userId])
  @@index([status])
}

// Invoice model
model Invoice {
  id                String    @id @default(uuid())
  userId            String    @map("user_id")
  helcimInvoiceId   String?   @unique @map("helcim_invoice_id")
  invoiceNumber     String    @unique @map("invoice_number")
  amountDue         Decimal   @map("amount_due") @db.Decimal(10, 2)
  amountPaid        Decimal   @map("amount_paid") @db.Decimal(10, 2)
  currency          String    @default("USD")
  status            String
  dueDate           DateTime  @map("due_date")
  paidAt            DateTime? @map("paid_at")
  invoicePdfUrl     String?   @map("invoice_pdf_url")
  createdAt         DateTime  @default(now()) @map("created_at")

  // Relations
  user              User      @relation(fields: [userId], references: [id])

  @@map("invoices")
  @@index([userId])
  @@index([status])
}

// Payment Method model
model PaymentMethod {
  id                String   @id @default(uuid())
  userId            String   @map("user_id")
  helcimCardToken   String   @unique @map("helcim_card_token")
  type              String
  last4             String
  brand             String
  expMonth          Int      @map("exp_month")
  expYear           Int      @map("exp_year")
  cardholderName    String?  @map("cardholder_name")
  isDefault         Boolean  @default(false) @map("is_default")
  createdAt         DateTime @default(now()) @map("created_at")

  // Relations
  user              User     @relation(fields: [userId], references: [id])

  @@map("payment_methods")
  @@index([userId])
}

// Audit Log model
model AuditLog {
  id         String   @id @default(uuid())
  userId     String?  @map("user_id")
  action     String
  ipAddress  String?  @map("ip_address")
  userAgent  String?  @map("user_agent")
  metadata   Json?
  createdAt  DateTime @default(now()) @map("created_at")

  // Relations
  user       User?    @relation(fields: [userId], references: [id])

  @@map("audit_logs")
  @@index([userId])
  @@index([action])
  @@index([createdAt])
}
```

### Database Indexes

**Performance Optimization:**
- `users.email` - UNIQUE index for fast login lookup
- `payments.user_id` - Fast payment history queries
- `payments.status` - Filter by payment status
- `payments.created_at` - Date range queries
- `subscriptions.user_id` - User subscription lookup
- `subscriptions.status` - Active subscription filtering
- `invoices.invoice_number` - UNIQUE for invoice lookup

### Migration Commands

```bash
# Create migration
npx prisma migrate dev --name init

# Apply migrations to production
npx prisma migrate deploy

# Generate Prisma Client
npx prisma generate

# Reset database (DEV ONLY!)
npx prisma migrate reset

# View database in Prisma Studio
npx prisma studio
```

---

## API Endpoints

### Authentication Routes (`/api/auth`)

```typescript
POST   /api/auth/register
Body: {
  email: string,
  password: string,
  firstName: string,
  lastName: string,
  gdprConsent: boolean
}
Response: {
  user: User,
  accessToken: string,
  refreshToken: string
}

POST   /api/auth/login
Body: {
  email: string,
  password: string
}
Response: {
  user: User,
  accessToken: string,
  refreshToken: string
}

POST   /api/auth/logout
Headers: { Authorization: "Bearer <token>" }
Response: { message: "Logged out successfully" }

POST   /api/auth/refresh-token
Body: { refreshToken: string }
Response: {
  accessToken: string,
  refreshToken: string
}

POST   /api/auth/forgot-password
Body: { email: string }
Response: { message: "Password reset email sent" }

POST   /api/auth/reset-password
Body: {
  token: string,
  newPassword: string
}
Response: { message: "Password reset successful" }

GET    /api/auth/me
Headers: { Authorization: "Bearer <token>" }
Response: { user: User }
```

### Payment Routes (`/api/payments`)

```typescript
POST   /api/payments/create-payment-intent
Headers: { Authorization: "Bearer <token>" }
Body: {
  amount: number,
  currency: string,
  description: string,
  paymentMethodId?: string
}
Response: {
  paymentId: string,
  clientSecret: string
}

POST   /api/payments/confirm
Headers: { Authorization: "Bearer <token>" }
Body: {
  paymentId: string,
  cardToken: string
}
Response: {
  payment: Payment,
  status: string
}

GET    /api/payments/history
Headers: { Authorization: "Bearer <token>" }
Query: {
  page?: number,
  limit?: number,
  status?: string
}
Response: {
  payments: Payment[],
  total: number,
  page: number
}

GET    /api/payments/:id
Headers: { Authorization: "Bearer <token>" }
Response: { payment: Payment }

POST   /api/payments/refund/:id
Headers: { Authorization: "Bearer <token>" }
Body: {
  amount?: number,  // Partial refund
  reason?: string
}
Response: {
  refund: Refund,
  payment: Payment
}
```

### Subscription Routes (`/api/subscriptions`)

```typescript
GET    /api/subscriptions/plans
Response: {
  plans: Plan[]
}

POST   /api/subscriptions/create
Headers: { Authorization: "Bearer <token>" }
Body: {
  planId: string,
  paymentMethodId: string
}
Response: {
  subscription: Subscription
}

GET    /api/subscriptions/active
Headers: { Authorization: "Bearer <token>" }
Response: {
  subscriptions: Subscription[]
}

PUT    /api/subscriptions/:id/cancel
Headers: { Authorization: "Bearer <token>" }
Body: {
  cancelAtPeriodEnd: boolean
}
Response: {
  subscription: Subscription
}

PUT    /api/subscriptions/:id/update
Headers: { Authorization: "Bearer <token>" }
Body: {
  planId?: string,
  paymentMethodId?: string
}
Response: {
  subscription: Subscription
}

GET    /api/subscriptions/:id
Headers: { Authorization: "Bearer <token>" }
Response: {
  subscription: Subscription
}
```

### Invoice Routes (`/api/invoices`)

```typescript
GET    /api/invoices
Headers: { Authorization: "Bearer <token>" }
Query: {
  page?: number,
  limit?: number,
  status?: string
}
Response: {
  invoices: Invoice[],
  total: number
}

GET    /api/invoices/:id
Headers: { Authorization: "Bearer <token>" }
Response: {
  invoice: Invoice
}

GET    /api/invoices/:id/pdf
Headers: { Authorization: "Bearer <token>" }
Response: PDF file download

POST   /api/invoices/send/:id
Headers: { Authorization: "Bearer <token>" }
Response: {
  message: "Invoice sent successfully"
}
```

### Payment Method Routes (`/api/payment-methods`)

```typescript
POST   /api/payment-methods/attach
Headers: { Authorization: "Bearer <token>" }
Body: {
  cardToken: string,
  cardholderName: string,
  setAsDefault: boolean
}
Response: {
  paymentMethod: PaymentMethod
}

GET    /api/payment-methods
Headers: { Authorization: "Bearer <token>" }
Response: {
  paymentMethods: PaymentMethod[]
}

DELETE /api/payment-methods/:id
Headers: { Authorization: "Bearer <token>" }
Response: {
  message: "Payment method deleted"
}

PUT    /api/payment-methods/:id/default
Headers: { Authorization: "Bearer <token>" }
Response: {
  paymentMethod: PaymentMethod
}
```

### Webhook Routes (`/api/webhooks`)

```typescript
POST   /api/webhooks/helcim
Headers: {
  x-helcim-signature: string
}
Body: {
  event: string,
  data: object
}
Response: { received: true }
```

### GDPR Routes (`/api/gdpr`)

```typescript
GET    /api/gdpr/export-data
Headers: { Authorization: "Bearer <token>" }
Response: JSON file with all user data

POST   /api/gdpr/delete-account
Headers: { Authorization: "Bearer <token>" }
Body: {
  confirmation: "DELETE MY ACCOUNT"
}
Response: {
  message: "Account deletion scheduled"
}
```

---

## Helcim Integration

### API Configuration

```typescript
// backend/src/config/helcim.ts

export const helcimConfig = {
  baseUrl: 'https://api.helcim.com/v2',
  apiToken: process.env.HELCIM_API_TOKEN,
  webhookSecret: process.env.HELCIM_WEBHOOK_SECRET,
  timeout: 30000,
  retryAttempts: 3
};
```

### Helcim Service Implementation

```typescript
// backend/src/services/helcimService.ts

import axios from 'axios';
import { helcimConfig } from '../config/helcim';

class HelcimService {
  private client;

  constructor() {
    this.client = axios.create({
      baseURL: helcimConfig.baseUrl,
      headers: {
        'Authorization': `Bearer ${helcimConfig.apiToken}`,
        'Content-Type': 'application/json'
      },
      timeout: helcimConfig.timeout
    });
  }

  // Create customer
  async createCustomer(data: {
    email: string;
    firstName: string;
    lastName: string;
  }) {
    const response = await this.client.post('/customers', data);
    return response.data;
  }

  // Process payment
  async processPayment(data: {
    amount: number;
    currency: string;
    cardToken: string;
    customerId?: string;
  }) {
    const response = await this.client.post('/payment', {
      amount: data.amount,
      currency: data.currency,
      cardToken: data.cardToken,
      customerId: data.customerId
    });
    return response.data;
  }

  // Create card token
  async createCardToken(cardData: {
    cardNumber: string;
    cvv: string;
    expiry: string;
  }) {
    const response = await this.client.post('/card-tokens', cardData);
    return response.data;
  }

  // Create recurring plan
  async createRecurringPlan(data: {
    customerId: string;
    amount: number;
    frequency: string;
    cardToken: string;
  }) {
    const response = await this.client.post('/recurring', data);
    return response.data;
  }

  // Cancel subscription
  async cancelSubscription(subscriptionId: string) {
    const response = await this.client.delete(`/recurring/${subscriptionId}`);
    return response.data;
  }

  // Refund transaction
  async refundTransaction(transactionId: string, amount?: number) {
    const response = await this.client.post('/refund', {
      transactionId,
      amount
    });
    return response.data;
  }

  // Verify webhook signature
  verifyWebhookSignature(payload: string, signature: string): boolean {
    const crypto = require('crypto');
    const expectedSignature = crypto
      .createHmac('sha256', helcimConfig.webhookSecret)
      .update(payload)
      .digest('hex');
    return signature === expectedSignature;
  }
}

export default new HelcimService();
```

### Webhook Handler

```typescript
// backend/src/controllers/webhookController.ts

import { Request, Response } from 'express';
import helcimService from '../services/helcimService';
import prisma from '../config/database';

export const handleHelcimWebhook = async (req: Request, res: Response) => {
  try {
    const signature = req.headers['x-helcim-signature'] as string;
    const payload = JSON.stringify(req.body);

    // Verify signature
    if (!helcimService.verifyWebhookSignature(payload, signature)) {
      return res.status(401).json({ error: 'Invalid signature' });
    }

    const { event, data } = req.body;

    // Handle different event types
    switch (event) {
      case 'transaction.success':
        await handleTransactionSuccess(data);
        break;
      case 'transaction.declined':
        await handleTransactionDeclined(data);
        break;
      case 'recurring.payment.success':
        await handleRecurringPaymentSuccess(data);
        break;
      case 'recurring.payment.failed':
        await handleRecurringPaymentFailed(data);
        break;
      case 'invoice.paid':
        await handleInvoicePaid(data);
        break;
      default:
        console.log(`Unhandled event: ${event}`);
    }

    res.json({ received: true });
  } catch (error) {
    console.error('Webhook error:', error);
    res.status(500).json({ error: 'Webhook processing failed' });
  }
};

async function handleTransactionSuccess(data: any) {
  await prisma.payment.update({
    where: { helcimTransactionId: data.transactionId },
    data: { status: 'completed' }
  });
}

// ... other webhook handlers
```

---

## Security Implementation

### JWT Authentication

```typescript
// backend/src/middleware/auth.ts

import jwt from 'jsonwebtoken';
import { Request, Response, NextFunction } from 'express';

interface JWTPayload {
  userId: string;
  email: string;
}

export const authenticateToken = (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'Access token required' });
  }

  try {
    const payload = jwt.verify(
      token,
      process.env.JWT_SECRET!
    ) as JWTPayload;
    req.user = payload;
    next();
  } catch (error) {
    return res.status(403).json({ error: 'Invalid or expired token' });
  }
};

export const generateTokens = (userId: string, email: string) => {
  const accessToken = jwt.sign(
    { userId, email },
    process.env.JWT_SECRET!,
    { expiresIn: '15m' }
  );

  const refreshToken = jwt.sign(
    { userId, email },
    process.env.JWT_REFRESH_SECRET!,
    { expiresIn: '7d' }
  );

  return { accessToken, refreshToken };
};
```

### Rate Limiting

```typescript
// backend/src/middleware/rateLimiter.ts

import rateLimit from 'express-rate-limit';

export const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100,
  message: 'Too many requests, please try again later'
});

export const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5, // 5 attempts per 15 minutes
  skipSuccessfulRequests: true,
  message: 'Too many login attempts, please try again later'
});

export const paymentLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 3, // 3 payment attempts per minute
  message: 'Too many payment attempts, please try again later'
});
```

### Input Validation

```typescript
// backend/src/middleware/validation.ts

import { z } from 'zod';
import { Request, Response, NextFunction } from 'express';

const paymentSchema = z.object({
  amount: z.number().positive().max(100000),
  currency: z.string().length(3),
  description: z.string().max(500).optional()
});

export const validatePayment = (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    paymentSchema.parse(req.body);
    next();
  } catch (error) {
    res.status(400).json({ error: 'Invalid payment data' });
  }
};
```

### Security Headers

```typescript
// backend/src/server.ts

import helmet from 'helmet';
import cors from 'cors';

app.use(helmet());
app.use(cors({
  origin: process.env.FRONTEND_URL,
  credentials: true
}));

app.use(helmet.contentSecurityPolicy({
  directives: {
    defaultSrc: ["'self'"],
    scriptSrc: ["'self'", "'unsafe-inline'", 'js.helcim.com'],
    styleSrc: ["'self'", "'unsafe-inline'"],
    imgSrc: ["'self'", 'data:', 'https:'],
    connectSrc: ["'self'", 'api.helcim.com']
  }
}));
```

---

## Deployment Strategy

### Environment Configuration

#### Production Environment Variables

```bash
# Backend (.env.production)
NODE_ENV=production
PORT=5000
DATABASE_URL=postgresql://user:pass@prod-db.railway.app:5432/payment_portal
JWT_SECRET=<generate-strong-secret>
JWT_REFRESH_SECRET=<generate-strong-secret>
HELCIM_API_TOKEN=<helcim-production-token>
HELCIM_WEBHOOK_SECRET=<helcim-webhook-secret>
FRONTEND_URL=https://payment-portal.vercel.app
EMAIL_SERVICE_API_KEY=<sendgrid-api-key>
AWS_S3_BUCKET=payment-portal-prod
AWS_ACCESS_KEY_ID=<aws-access-key>
AWS_SECRET_ACCESS_KEY=<aws-secret-key>
SENTRY_DSN=<sentry-dsn>
```

```bash
# Frontend (.env.production)
VITE_API_URL=https://api.payment-portal.com/api
VITE_HELCIM_TOKEN=<helcim-public-token>
```

### Deployment Platforms

#### Backend: Railway/Render

**railway.json:**
```json
{
  "$schema": "https://railway.app/railway.schema.json",
  "build": {
    "builder": "NIXPACKS",
    "buildCommand": "npm install && npx prisma generate && npm run build"
  },
  "deploy": {
    "startCommand": "npm run start",
    "restartPolicyType": "ON_FAILURE",
    "restartPolicyMaxRetries": 10
  }
}
```

**Deployment steps:**
```bash
# Connect Railway to GitHub
railway login
railway link

# Deploy
railway up

# Run migrations
railway run npx prisma migrate deploy
```

#### Frontend: Vercel

**vercel.json:**
```json
{
  "buildCommand": "npm run build",
  "outputDirectory": "dist",
  "devCommand": "npm run dev",
  "installCommand": "npm install",
  "framework": "vite",
  "rewrites": [
    { "source": "/(.*)", "destination": "/index.html" }
  ]
}
```

**Deployment:**
```bash
# Install Vercel CLI
npm i -g vercel

# Deploy
vercel --prod
```

### CI/CD Pipeline

See `.github/workflows/ci.yml` in [GitHub Setup Guide](./github-setup-guide.md)

---

## Monitoring & Logging

### Winston Logger Configuration

```typescript
// backend/src/utils/logger.ts

import winston from 'winston';

const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  defaultMeta: { service: 'payment-portal-api' },
  transports: [
    new winston.transports.File({
      filename: 'logs/error.log',
      level: 'error'
    }),
    new winston.transports.File({
      filename: 'logs/combined.log'
    })
  ]
});

if (process.env.NODE_ENV !== 'production') {
  logger.add(new winston.transports.Console({
    format: winston.format.simple()
  }));
}

export default logger;
```

### Error Tracking with Sentry

```typescript
// backend/src/config/sentry.ts

import * as Sentry from '@sentry/node';

Sentry.init({
  dsn: process.env.SENTRY_DSN,
  environment: process.env.NODE_ENV,
  tracesSampleRate: 1.0
});

export default Sentry;
```

### Health Check Endpoint

```typescript
// backend/src/routes/health.ts

router.get('/health', async (req, res) => {
  const health = {
    status: 'ok',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    database: await checkDatabase(),
    helcim: await checkHelcimAPI()
  };

  const statusCode = health.database && health.helcim ? 200 : 503;
  res.status(statusCode).json(health);
});
```

---

## Backup & Recovery

### Database Backup Strategy

```bash
# Daily automated backup (cron job)
0 2 * * * pg_dump $DATABASE_URL | gzip > backup_$(date +\%Y\%m\%d).sql.gz

# Upload to S3
aws s3 cp backup_$(date +\%Y\%m\%d).sql.gz s3://backups/database/
```

### Recovery Procedure

```bash
# Download latest backup
aws s3 cp s3://backups/database/backup_20240101.sql.gz .

# Restore database
gunzip backup_20240101.sql.gz
psql $DATABASE_URL < backup_20240101.sql
```

---

## Performance Optimization

### Database Query Optimization

```typescript
// Use Prisma select to fetch only needed fields
const users = await prisma.user.findMany({
  select: {
    id: true,
    email: true,
    firstName: true,
    lastName: true
  },
  where: { deletedAt: null }
});

// Use pagination
const payments = await prisma.payment.findMany({
  skip: (page - 1) * limit,
  take: limit,
  orderBy: { createdAt: 'desc' }
});
```

### Caching Strategy (Optional Redis)

```typescript
import Redis from 'ioredis';

const redis = new Redis(process.env.REDIS_URL);

// Cache subscription plans
const plans = await redis.get('subscription:plans');
if (!plans) {
  const freshPlans = await fetchPlansFromDB();
  await redis.set('subscription:plans', JSON.stringify(freshPlans), 'EX', 3600);
}
```

---

## Success Criteria

✅ All endpoints functional and tested
✅ Database properly indexed and optimized
✅ Security measures implemented
✅ Deployment automated via CI/CD
✅ Monitoring and logging configured
✅ Backup strategy in place
✅ Documentation complete

---

**Document Version:** 1.0
**Last Updated:** December 2024
**Maintained by:** Development Team
