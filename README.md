# Decentralized Identity Management System

## Overview
BlockID is a comprehensive decentralized identity management system built on blockchain technology. It provides a secure and flexible way to manage digital identities, social relationships, and reputation systems in a decentralized manner.

## Features
- Secure identity registration and management
- Contact information verification
- Social relationship tracking (followers/following)
- Identity recovery system
- Reputation and badge management
- Account security with lockout protection
- Verified status tracking

## Technical Specifications
- Written in Clarity smart contract language
- Compatible with Stacks blockchain
- Uses principal-based identity mapping
- Implements secure data validation
- Built-in rate limiting and security measures

## Data Structures
### Identity Data
- Handle (3-50 characters)
- Contact information (5-100 characters)
- Optional avatar URL
- Optional bio (up to 500 characters)
- Creation and update timestamps
- Verification status
- Social links (up to 5)
- Recovery address

### Metadata
- Reputation score
- Trust level
- Badges (up to 10)
- Following/Followers count

## Security Features
- Password hash validation
- Account lockout protection
- Admin-only badge management
- Input validation for all fields
- Protected recovery address system

## Usage

### Registration
```clarity
(contract-call? .blockid register-identity 
    "username" 
    "user@example.com"
    (some u"Bio text") 
    <password-hash>)
```

### Following Users
```clarity
(contract-call? .blockid follow-identity <principal-to-follow>)
```

### Setting Recovery Address
```clarity
(contract-call? .blockid set-recovery-address <recovery-principal>)
```

## Development

### Prerequisites
- Clarity CLI
- Stacks blockchain development environment
- Node.js and NPM (for testing environment)

### Testing
Run the test suite:
```bash
clarinet test
```

### Deployment
1. Build the contract:
```bash
clarinet build
```

2. Deploy to testnet:
```bash
clarinet deploy --testnet
```

## Contributing
1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request


## Contact
For questions and support, please open an issue in the repository.