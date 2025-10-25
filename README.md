# coremp135-bsp

Base for building a buildroot linux image for the coremp135. 

## Intended use

This is intended to be used as a BR2_EXTERNAL tree, along with a second, application specific
external tree. 

## Configuration

### RAUC

To generate RAUC bundles, configure the following environment variables during build: 

- `RAUC_KEY_PATH`: Path to the private key PEM file for signing bundles
- `RAUC_CERT_PATH`: Points to the certificate PEM file which is installed on the device for
  verifying bundles
- `RAUC_COMPATIBILITY`: A unique compatibility string for your device used determine if images can
  be installed. The default is `coremp135-example`.

### Data Partition

By default, the BSP creates two rootfs partitions for holding the linux system and application --
these are what are updated by an RAUC bundle -- and a data partition for storing data which is not
replaced during OTA. By default, the data partition is an ext4 filesystem, but it can be configured
as exFAT by setting the `COREMP135_EXFAT_DATA` environment variable.

### Authorized SSH key

To log in via SSH, you can place a public key into the target directory at
$TARGET_DIR/root/.ssh/authorized_keys.

For example, in a post-build script:

```bash
# Copy public key for login
if [ -e ~/.ssh/id_rsa.pub ]; then
  mkdir -p $TARGET_DIR/root/.ssh
  cp ~/.ssh/id_rsa.pub $TARGET_DIR/root/.ssh/authorized_keys
fi
```
