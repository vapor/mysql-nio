#ifndef C_MYSQL_OPENSSL_H
#define C_MYSQL_OPENSSL_H

#include <openssl/evp.h>

#if (OPENSSL_VERSION_NUMBER < 0x10100000L) || defined(LIBRESSL_VERSION_NUMBER)
EVP_MD_CTX *EVP_MD_CTX_new(void) {
	return EVP_MD_CTX_create();
}
void EVP_MD_CTX_free(EVP_MD_CTX *ctx) {
	return EVP_MD_CTX_destroy(ctx);
}
#endif

#endif
