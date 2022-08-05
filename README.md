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

## Pseudocode
1. Original P12 Installed on Client Device
2. Retrieve CA Trust from Certificate Authority (curl >> est)
3. Decrypt original P12 on Client Device and save as client.pem (openssl)
4. Extract Private key from original P12 (openssl pkcs12 -in original.p12 -out key.pem -nodes -password pass:YourPassword)
5. Generate base-64 PKCS#10 certificate request from private key (openssl req -new -subj "/C=US/CN=$cnValue" -key key.pem -out req.pem)
6. Submit EST Simple Reenroll request (curl)
7. Convert result p7b to pem (openssl pkcs7 -in output.p7b -inform DER -out result.pem -print_certs)
8. Generate new openssl pkcs12 (openssl pkcs12 -export -inkey key.pem -in result.pem -name $cnValue -out final_output.p12

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
