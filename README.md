# CreaS: Decentralized Creator Revenue Sharing Platform

## Overview
CreaS is a decentralized platform built on the Stacks blockchain that enables transparent revenue sharing and licensing management for creative collaborations. Using smart contracts, it automates revenue distribution among collaborators while maintaining a transparent record of all transactions and usage rights.

## Features
- Automated revenue splitting between collaborators with configurable share percentages
- Transparent royalty distribution system with real-time tracking
- Built-in licensing and usage tracking with support for multiple license types
- Real-time earnings monitoring and withdrawal system
- Verified collaborator system with role-based access
- Permanent record of collaboration terms and project history
- Project activation/deactivation management
- Comprehensive statistics and analytics

## Technical Architecture
The platform consists of four main components:
1. Smart Contract (Clarity)
2. Frontend Interface (React/Next.js)
3. IPFS Integration for Content Storage
4. Testing Framework (Vitest)

### Smart Contract Structure
- Project Management (creation, activation/deactivation)
- Collaborator Management (roles, verification, shares)
- Revenue Distribution (automatic calculation and distribution)
- Licensing Management (usage tracking, payment processing)
- Statistics and Analytics (revenue, collaborators, distributions)

## Getting Started

### Prerequisites
- Stacks wallet (Hiro Wallet recommended)
- Clarity CLI
- Node.js and npm
- Vitest for testing

### Installation

1. Clone the repository
```bash
git clone https://github.com/yourusername/CreaS
cd CreaS
```

2. Install dependencies
```bash
npm install
```

3. Install development dependencies
```bash
npm install -D vitest @stacks/testing
```

4. Deploy the smart contract
```bash
clarinet contract deploy
```

## Testing

Run the test suite:
```bash
npm test
```

The test suite covers:
- Project creation and management
- Collaborator addition and verification
- Revenue distribution
- License usage recording
- Project status management
- Earnings withdrawal
- Statistics calculation

## Usage

### Creating a Project
```clarity
(contract-call? .creats create-project 
    "My Creative Project" 
    0x123... ;; Content hash
    "MIT License"
)
```

### Adding Collaborators
```clarity
(contract-call? .creats add-collaborator 
    u1 
    'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7 
    u30 
    "Artist"
)
```

### Recording License Usage
```clarity
(contract-call? .creats record-license-usage 
    u1 
    "Commercial Use" 
    u1000
)
```

### Distributing Revenue
```clarity
(contract-call? .creats distribute-revenue 
    u1 
    u1000
)
```

### Withdrawing Earnings
```clarity
(contract-call? .creats withdraw-earnings 
    u1
)
```

## Security Features
- Comprehensive input validation
- Role-based access control
- Protected revenue distribution mechanism
- Verified collaborator system
- Project status management
- Secure earnings withdrawal process

## Contract Constants
- Maximum project ID: 1,000,000
- Share percentage range: 1-100
- Required field validations:
  - Title length: 3-256 characters
  - License type length: 3-64 characters
  - Role length: 3-64 characters
  - Content hash: 32 bytes

## Future Enhancements
1. Integration with NFT marketplaces
2. Advanced licensing templates
3. Dispute resolution mechanism
4. Cross-chain compatibility
5. Enhanced analytics dashboard
6. Automated testing pipeline
7. Integration testing with frontend
8. Performance optimization for large-scale distributions

## Contributing
We welcome contributions! Please ensure you:
1. Write tests for new features
2. Follow the existing code style
3. Update documentation as needed
4. Submit PRs with clear descriptions
5. Run the full test suite before submitting

## Disclaimer
This is a beta version of the platform. Please use caution when handling real assets and thoroughly test all functionality in a test environment first.

