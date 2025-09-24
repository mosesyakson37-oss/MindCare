# Mental Health Access Pass Smart Contracts

## Overview

This PR introduces a comprehensive blockchain-based mental health access token system called **MindCare**, designed to facilitate transparent and secure management of counseling session credits using Clarity smart contracts on the Stacks blockchain.

## Core Features Implemented

### 🎫 Token Management System (`mind-care-token.clar`)
- **SIP-010 Compatible**: Full compliance with Stacks fungible token standard
- **Access Pass Tokens**: Mintable tokens representing counseling session credits (MCAP)
- **Session Creation**: Users can create counseling sessions with optional provider assignment
- **Token Locking**: Automatic token escrow during active sessions
- **Session Redemption**: Providers can redeem tokens upon session completion
- **Administrative Controls**: Secure token minting and burning with role-based permissions

### 🏥 Provider Registry System (`provider-registry.clar`)
- **Provider Registration**: Mental health professionals can register with credentials
- **Verification System**: Administrative verification of provider credentials
- **Specialty Tracking**: Support for multiple specialties per provider
- **Rating & Reviews**: Client feedback system with 1-5 star ratings
- **Session Statistics**: Comprehensive tracking of provider performance metrics
- **Status Management**: Active/inactive provider status controls

## Technical Implementation

### Smart Contract Architecture
```clarity
MindCare Token Contract (344+ lines)
├── SIP-010 Token Standard Implementation
├── Session Management System
├── Administrative Functions
└── Balance & Transfer Management

Provider Registry Contract (425+ lines)
├── Provider Profile Management
├── Verification & Credentials System
├── Review & Rating System
└── Session Statistics Tracking
```

### Key Functions

#### Token Contract
- `mint` - Administrative token minting
- `transfer` - Standard token transfers
- `create-session` - Initialize counseling sessions
- `complete-session` - Client-initiated session completion
- `redeem-session` - Provider token redemption

#### Provider Registry
- `register-provider` - New provider registration
- `verify-provider` - Administrative verification
- `submit-review` - Client review submission
- `record-session-completion` - Session statistics tracking

## Security Features

✅ **Role-Based Access Control**: Admin-only functions protected  
✅ **Input Validation**: Comprehensive parameter checking  
✅ **Balance Verification**: Prevents over-spending and double-spending  
✅ **Session Authorization**: Only authorized parties can complete sessions  
✅ **Review Authentication**: Prevents self-reviews and duplicate submissions  

## Testing & Validation

- ✅ **Contract Syntax**: All contracts pass `clarinet check`
- ✅ **Unit Tests**: Basic test suites generated and passing
- ✅ **CI/CD Pipeline**: GitHub Actions workflow for automated syntax checking

## Token Economics

- **Token Symbol**: MCAP (MindCare Access Pass)
- **Decimals**: 6
- **Use Case**: 1 token = 1 counseling session hour
- **Supply Model**: Administrative minting with controlled distribution
- **Redemption**: Providers earn tokens for completed sessions

## Provider Network

- **Registration**: Open registration with verification requirement
- **Specialties**: Support for up to 10 specialties per provider
- **Credentials**: License number and professional credentials tracking
- **Performance**: Session completion rates and earnings tracking

## Quality Assurance

- **Review System**: 1-5 star rating system with comments
- **Statistics Tracking**: Comprehensive provider performance metrics
- **Session History**: Complete audit trail of all transactions
- **Transparency**: All operations logged and publicly verifiable

## Files Changed

### New Files Added
- `contracts/mind-care-token.clar` - Core token contract (344 lines)
- `contracts/provider-registry.clar` - Provider management contract (425 lines)  
- `.github/workflows/ci.yml` - CI/CD pipeline configuration
- `PR-DETAILS.md` - This documentation

### Configuration Updates
- `Clarinet.toml` - Updated with new contract definitions
- `package.json` - Project dependencies and test configuration

## Future Roadmap

- [ ] Integration with major mental health platforms
- [ ] Mobile application development  
- [ ] Advanced analytics dashboard
- [ ] Insurance integration capabilities
- [ ] Multi-language support

## Compliance & Privacy

This system is designed to facilitate access to mental health services while maintaining strict privacy standards. All personal health information remains off-chain and is handled according to relevant privacy regulations including HIPAA compliance considerations.

## Getting Started

```bash
# Install dependencies
npm install

# Check contract syntax
clarinet check

# Run tests
npm test

# Deploy to testnet
clarinet deployment deploy --network testnet
```

---

**Ready for Review**: This implementation provides a solid foundation for a mental health access token system with comprehensive provider management, built using clean Clarity syntax and following blockchain security best practices.
