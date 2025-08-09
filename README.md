# Decentralized Public Delivery and Courier Services Oversight

A comprehensive blockchain-based system for managing and overseeing public delivery and courier services using Clarity smart contracts on the Stacks blockchain.

## System Overview

This system provides decentralized oversight for delivery and courier services through five interconnected smart contracts:

### 1. Courier Service Licensing Contract (`courier-licensing.clar`)
- Issues and manages permits for package delivery and messenger services
- Tracks license status, expiration dates, and service ratings
- Handles license renewals and revocations

### 2. Commercial Vehicle Registration Contract (`vehicle-registration.clar`)
- Manages permits for delivery trucks and commercial vehicles
- Tracks vehicle specifications, insurance status, and operational zones
- Handles vehicle registration renewals and transfers

### 3. Package Security Compliance Contract (`package-security.clar`)
- Ensures proper handling and security of delivered packages and documents
- Manages security certifications and compliance records
- Tracks security incidents and resolutions

### 4. Traffic and Parking Coordination Contract (`traffic-parking.clar`)
- Manages delivery vehicle parking and loading zone usage
- Coordinates time-based parking permits and zone allocations
- Tracks violations and manages penalty systems

### 5. Insurance and Liability Verification Contract (`insurance-verification.clar`)
- Ensures delivery services maintain proper insurance coverage
- Verifies liability coverage amounts and policy validity
- Manages claims and coverage updates

## Key Features

- **Decentralized Governance**: No single point of control
- **Transparent Operations**: All activities recorded on blockchain
- **Automated Compliance**: Smart contract enforcement of regulations
- **Real-time Tracking**: Live status updates for all services
- **Penalty Management**: Automated fine and penalty systems

## Contract Architecture

Each contract operates independently while maintaining data consistency through standardized interfaces. The system uses:

- **Principal-based Authentication**: Stacks wallet addresses for identity
- **Time-based Permits**: Block height for expiration tracking
- **Rating Systems**: Community-driven service quality metrics
- **Penalty Mechanisms**: Automated enforcement of violations

## Getting Started

### Prerequisites
- Clarinet CLI installed
- Node.js 18+ for testing
- Stacks wallet for deployment

### Installation

\`\`\`bash
git clone <repository-url>
cd delivery-oversight-system
npm install
clarinet check
\`\`\`

### Testing

\`\`\`bash
npm test
\`\`\`

### Deployment

\`\`\`bash
clarinet deploy --testnet
\`\`\`

## Usage Examples

### Register a Courier Service
\`\`\`clarity
(contract-call? .courier-licensing apply-for-license "Express Delivery Co" u1000)
\`\`\`

### Register a Commercial Vehicle
\`\`\`clarity
(contract-call? .vehicle-registration register-vehicle "ABC123" "delivery-truck" u5000)
\`\`\`

### Reserve a Loading Zone
\`\`\`clarity
(contract-call? .traffic-parking reserve-loading-zone "zone-downtown-1" u60)
\`\`\`

## Contract Interactions

The contracts are designed to work independently, allowing for:
- Modular upgrades and maintenance
- Independent scaling of different services
- Flexible integration with external systems

## Security Considerations

- All sensitive operations require proper authentication
- Time-based locks prevent rapid-fire transactions
- Penalty systems discourage malicious behavior
- Regular compliance checks ensure ongoing adherence

## Contributing

Please read the PR-DETAILS.md file for contribution guidelines and development standards.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
