# EST - Simple Reenroll
Bash script to generate client side EST simple reenroll requests

## Requirements
- curl
- openssl
- bash
- CertAgent 7.0.9.6

## Background
Initial device certificate (RSA4096 / SHA384) is issued from the Certificate Authority through a manual enrollment and issuance process. The public certificate is combined with the private key and 3DES encrypted to form a PKCS#12 (PFX / P12). The system administrator installs the P12 on the device.

Prior to expiration of the original public certificate, a reenroll request is submit via the EST mechanism. The original client certificate is used to provide certificate authorization during the enrollment. A new certificate request is generated from the original private key and must have matching Common Name (CN) as the client certificate.

## Process Diagram
```
┌────────────┐                     ┌────────────┐                      ┌────────────┐
│ EST Client │                     │ EST Server │                      │   EST CA   │
└─────┬──────┘                     └──────┬─────┘                      └──────┬─────┘
      │                                   │                                   │
      │                                   │                                   │
      │                                   │                                   │
      │    (EST) Request certification    │                                   │
      ├──────────────────────────────────►│                                   │
      │                                   │                                   │
      │             Trust chain           │                                   │
      │◄──────────────────────────────────┤                                   │
      │                                   │                                   │
      │  Validate chain                   │                                   │
      ├───────────────────┐               │                                   │
      │                   │               │                                   │
      │                   │               │                                   │
      │◄──────────────────┘               │                                   │
      │                                   │                                   │
      │Generate key and CSR               │                                   │
      ├───────────────────┐               │                                   │
      │                   │               │                                   │
      │                   │               │                                   │
      │◄──────────────────┘               │                                   │
      │                                   │                                   │
      │ (EST) PKCS#10 certificate request │                                   │
      ├──────────────────────────────────►│                                   │
      │                                   │                                   │
      │                                   │Validate client credent            │
      │                                   │(Certificate auth)                 │
      │                                   ├─────────────────────┐             │
      │                                   │                     │             │
      │                                   │                     │             │
      │                                   │◄────────────────────┘             │
      │                                   │                                   │
      │                                   │         Request certificate       │
      │                                   ├──────────────────────────────────►│
      │                                   │                                   │
      │                                   │              Certificate          │
      │                                   │◄──────────────────────────────────┤
      │                                   │                                   │
      │        PKCS#7 Certificate         │                                   │
      │◄──────────────────────────────────┤                                   │
      │                                   │                                   │
      │                                   │                                   │
      │                                   │                                   │
```

## Variables
- __dir : base script directory
- __certs : certificate store directory within base dir
- VERSION : Version number
- DETECTED_OS : Displays OS name and version for debuging
- dtg : Date Time Group
- cacert : location of ca root trust
- capuburi : Public EST URI via port 443
- cainturi : EST enrollment URI via port 8443
- cnvalue : CN used in both original certificate as well as renewals
- origp12 : location of original p12
- p12pass : Password used to encrypt/decrypt P12 and Private Keys

## Contact
Tony Cavella 
cavella_tony@bah.com
