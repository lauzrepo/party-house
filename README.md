# Payment Portal with Helcim Integration

A modern, secure payment portal designed for organizations with ~300 members, supporting one-time payments, recurring subscriptions, and invoice management.

## Overview

This payment portal provides a complete solution for payment processing with significant cost savings over traditional payment processors like Stripe. Built with React and Node.js, it integrates with Helcim for payment processing while maintaining PCI compliance and GDPR requirements.

### Key Features

- ✅ **One-time payments** - Process single transactions securely
- ✅ **Recurring subscriptions** - Automated billing for membership plans
- ✅ **Invoice generation** - Create, send, and track invoices
- ✅ **Multiple payment methods** - Support for cards and ACH
- ✅ **Payment method storage** - Save cards for future use
- ✅ **GDPR compliant** - Full data privacy controls
- ✅ **Email notifications** - Automated receipts and reminders
- ✅ **Payment history** - Complete transaction tracking

### Cost Savings

**Annual Processing Fees Comparison:**

| Processor | Annual Cost | Savings |
|-----------|-------------|---------|
| Helcim | $3,268/year | - |
| Stripe | $8,083/year | - |
| **Difference** | **-$4,815/year** | **59% reduction** |

See [Payment Processor Cost Comparison](./docs/payment-processor-cost-comparison.md) for detailed analysis.

## Tech Stack

### Frontend
- **React 18+** with TypeScript
- **Vite** - Fast build tool and dev server
- **React Router v6** - Client-side routing
- **Material-UI** or **Tailwind CSS** - UI components
- **React Hook Form** + **Zod** - Form validation
- **React Query** - Data fetching and caching
- **Axios** - HTTP client
- **Helcim.js** - Secure payment tokenization

### Backend
- **Node.js 18+ LTS**
- **Express.js** with TypeScript
- **PostgreSQL** - Relational database
- **Prisma ORM** - Type-safe database access
- **JWT** - Authentication tokens
- **Winston** - Structured logging
- **Helmet** - Security headers
- **Express-rate-limit** - API rate limiting

### Infrastructure
- **Database:** PostgreSQL (Railway/Render managed)
- **File Storage:** AWS S3 (invoice PDFs)
- **Email:** SendGrid or AWS SES
- **Hosting:** Railway/Render (backend), Vercel (frontend)

## Project Structure

```
payment-portal/
├── README.md
├── .gitignore
├── docs/
│   ├── payment-portal-infrastructure.md
│   ├── payment-processor-cost-comparison.md
│   └── github-setup-guide.md
├── frontend/
│   ├── src/
│   │   ├── components/
│   │   │   ├── payments/
│   │   │   ├── invoices/
│   │   │   ├── auth/
│   │   │   └── common/
│   │   ├── pages/
│   │   ├── services/
│   │   ├── hooks/
│   │   ├── contexts/
│   │   ├── utils/
│   │   └── types/
│   ├── package.json
│   ├── tsconfig.json
│   └── vite.config.ts
├── backend/
│   ├── src/
│   │   ├── controllers/
│   │   ├── services/
│   │   ├── models/
│   │   ├── middleware/
│   │   ├── routes/
│   │   ├── utils/
│   │   └── config/
│   ├── prisma/
│   ├── package.json
│   └── tsconfig.json
└── database/
    └── migrations/
```

## Quick Start

### Prerequisites

- Node.js 18+ LTS
- PostgreSQL 14+
- Helcim account (merchant account required)
- Git

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd payment-portal
   ```

2. **Install dependencies**
   ```bash
   # Backend
   cd backend
   npm install

   # Frontend
   cd ../frontend
   npm install
   ```

3. **Configure environment variables**
   ```bash
   # Copy example files
   cp backend/.env.example backend/.env
   cp frontend/.env.example frontend/.env

   # Edit with your credentials
   nano backend/.env
   nano frontend/.env
   ```

4. **Setup database**
   ```bash
   cd backend
   npx prisma migrate dev
   npx prisma generate
   ```

5. **Start development servers**
   ```bash
   # Terminal 1 - Backend
   cd backend
   npm run dev

   # Terminal 2 - Frontend
   cd frontend
   npm run dev
   ```

6. **Access the application**
   - Frontend: http://localhost:3000
   - Backend API: http://localhost:5000

## Documentation

- **[Infrastructure Guide](./docs/payment-portal-infrastructure.md)** - Complete technical architecture and deployment
- **[Cost Comparison](./docs/payment-processor-cost-comparison.md)** - Detailed ROI analysis
- **[GitHub Setup Guide](./docs/github-setup-guide.md)** - Repository configuration and CI/CD

## Security Features

- 🔒 **JWT Authentication** - 15-minute access tokens, 7-day refresh tokens
- 🔒 **Password Hashing** - bcrypt with 10+ rounds
- 🔒 **Rate Limiting** - Protection against brute force attacks
- 🔒 **CORS** - Whitelisted origins only
- 🔒 **Helmet** - Security headers on all responses
- 🔒 **HTTPS** - Forced SSL/TLS in production
- 🔒 **PCI Compliance** - No card data storage, tokenization only
- 🔒 **Input Validation** - Zod/Joi validation on all inputs
- 🔒 **SQL Injection Protection** - Prisma ORM parameterized queries
- 🔒 **XSS Protection** - Input sanitization

## GDPR Compliance

- ✅ Cookie consent banner
- ✅ Privacy policy page
- ✅ Data export functionality
- ✅ Account deletion (right to be forgotten)
- ✅ Consent tracking
- ✅ Data retention policies
- ✅ Audit logging

## API Documentation

### Authentication Endpoints
```
POST   /api/auth/register        - Register new user
POST   /api/auth/login           - Login user
POST   /api/auth/logout          - Logout user
POST   /api/auth/refresh-token   - Refresh access token
POST   /api/auth/forgot-password - Request password reset
POST   /api/auth/reset-password  - Reset password
GET    /api/auth/me              - Get current user
```

### Payment Endpoints
```
POST   /api/payments/create-payment-intent  - Initialize payment
POST   /api/payments/confirm                - Confirm payment
GET    /api/payments/history                - Get payment history
GET    /api/payments/:id                    - Get payment details
POST   /api/payments/refund/:id             - Refund payment
```

### Subscription Endpoints
```
GET    /api/subscriptions/plans    - List available plans
POST   /api/subscriptions/create   - Create subscription
GET    /api/subscriptions/active   - Get active subscriptions
PUT    /api/subscriptions/:id/cancel - Cancel subscription
PUT    /api/subscriptions/:id/update - Update subscription
GET    /api/subscriptions/:id      - Get subscription details
```

### Invoice Endpoints
```
GET    /api/invoices           - List invoices
GET    /api/invoices/:id       - Get invoice details
GET    /api/invoices/:id/pdf   - Download invoice PDF
POST   /api/invoices/send/:id  - Send invoice via email
```

## Testing

### Frontend Tests
```bash
cd frontend
npm test              # Run tests
npm run test:coverage # Generate coverage report
npm run test:e2e      # Run E2E tests with Cypress/Playwright
```

### Backend Tests
```bash
cd backend
npm test              # Run tests
npm run test:coverage # Generate coverage report
npm run test:integration # Run integration tests
```

### Test Coverage Requirements
- Frontend: 70% minimum
- Backend: 80% minimum

### Helcim Test Cards
```
Visa: 4111 1111 1111 1111
Mastercard: 5454 5454 5454 5454
Expiry: Any future date
CVV: Any 3 digits
```

## Development Workflow

### Phase 1 (Weeks 1-3) - Core Features
- [x] Project setup and structure
- [x] Database schema and migrations
- [x] Authentication system
- [x] Basic payment processing (one-time)
- [x] Helcim API integration

### Phase 2 (Weeks 4-7) - Advanced Features
- [ ] Subscription management
- [ ] Payment method storage
- [ ] User dashboard
- [ ] Payment history
- [ ] Webhook handling

### Phase 3 (Weeks 8-11) - Finishing Touches
- [ ] Invoice generation
- [ ] Email notifications
- [ ] GDPR features
- [ ] Admin panel (optional)
- [ ] Testing and deployment

## Deployment

### Environment Configuration

See [Infrastructure Guide](./docs/payment-portal-infrastructure.md) for complete deployment instructions.

### Deployment Checklist
- [ ] Environment variables configured
- [ ] Database migrations run
- [ ] Helcim account verified and approved
- [ ] Webhook endpoints configured in Helcim dashboard
- [ ] SSL certificates installed
- [ ] CORS configured properly
- [ ] Rate limiting enabled
- [ ] Error monitoring (Sentry) configured
- [ ] Backup strategy implemented
- [ ] CI/CD pipeline setup

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Quality Standards
- TypeScript strict mode enabled, no `any` types
- ESLint (Airbnb config)
- Prettier for code formatting
- JSDoc comments for all public functions
- Proper error handling with try-catch blocks
- Conventional commits format

## Troubleshooting

### Common Issues

**Database connection errors**
- Verify PostgreSQL is running
- Check DATABASE_URL in .env
- Ensure database exists

**Helcim API errors**
- Verify API token is correct
- Check Helcim account is approved
- Confirm webhook secret matches

**Frontend build errors**
- Clear node_modules and reinstall
- Check Node.js version (18+ required)
- Verify all environment variables are set

## Support

- 📚 [Helcim API Documentation](https://docs.helcim.com/)
- 📚 [React Documentation](https://react.dev/)
- 📚 [Express Documentation](https://expressjs.com/)
- 📚 [Prisma Documentation](https://www.prisma.io/docs/)

## License

[Your License Here]

## Acknowledgments

- Helcim for providing competitive payment processing rates
- Open source community for the amazing tools and frameworks
