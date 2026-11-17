import { UpdateMeSchema, UserSchema } from '../../schemas/user.schema.js';
import { registry } from '../registry.js';
import { API_PREFIX, errors, json, ok } from './helpers.js';

const tags = ['Profile'];

registry.registerPath({
  method: 'get',
  path: `${API_PREFIX}/me`,
  tags,
  summary: 'Oturumdaki kullanıcının profili',
  description: 'Profil yoksa ilk çağrıda token bilgilerinden oluşturulur.',
  responses: { 200: ok(UserSchema), ...errors() },
});

registry.registerPath({
  method: 'patch',
  path: `${API_PREFIX}/me`,
  tags,
  summary: 'Profili güncelle',
  request: { body: { required: true, content: json(UpdateMeSchema) } },
  responses: { 200: ok(UserSchema), ...errors(400) },
});
