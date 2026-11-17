import { extendZodWithOpenApi } from '@asteasolutions/zod-to-openapi';
import { z } from 'zod';

// `.openapi()` metodunu ekler. Tüm şemalar `z`'yi buradan import etmelidir.
extendZodWithOpenApi(z);

export { z };
