__kernel void core256
(
 const __global uint *input,
 __global uint *global_state,
 const __global uint *consts,
 __local uint *cache,
 uint blocks
)
{
	uint local_id = get_local_id (0);
	uint parallel_index = get_global_id (0);
	uint parallels = get_global_size (0);
	uint s0, s1, s2, s3, s4, s5, s6, s7;
	uint si0, si1, si2, si3, si4, si5, si6, si7;
	__private uint buf[64];
	uint cache_copy_size = 64 / get_local_size (0);
	if (cache_copy_size == 0) cache_copy_size = 1;

	global_state += parallel_index * 8;

	if (local_id < 64) {
		uint offset = cache_copy_size * local_id;
		for (uint i = 0; i < cache_copy_size; i ++)
			cache[offset + i] = consts[offset + i];
	}
	barrier (CLK_LOCAL_MEM_FENCE);
	s0 = global_state[0]; s1 = global_state[1]; s2 = global_state[2]; s3 = global_state[3];
	s4 = global_state[4]; s5 = global_state[5]; s6 = global_state[6]; s7 = global_state[7];

	for (uint i = 0; i < blocks; i ++) {
		for (uint j = 0; j < 16; j ++) {
			uint m = input[(parallels * i + parallel_index) * 16 + j];
			buf[j] = m;//(m >> 24) | ((m >> 8) & 0xff00) | ((m << 8) & 0xff0000) | (m << 24);
		}
		for (uint j = 16; j < 64; j ++) {
			uint t1 = buf[j - 15];
			t1 = (((t1 >> 7) | (t1 << 25)) ^ ((t1 >> 18) | (t1 << 14)) ^ (t1 >> 3));
			uint t2 = buf[j - 2];
			t2 = (((t2 >> 17) | (t2 << 15)) ^ ((t2 >> 19) | (t2 << 13)) ^ (t2 >> 10));
			buf[j] = t2 + buf[j - 7] + t1 + buf[j - 16];
		}
		si0 = s0; si1 = s1; si2 = s2; si3 = s3;
		si4 = s4; si5 = s5; si6 = s6; si7 = s7;
		for (uint j = 0; j < 64; j ++) {
			uint t1 = si7 + (((si4 >> 6) | (si4 << 26)) ^ ((si4 >> 11) | (si4 << 21)) ^ ((si4 >> 25) | (si4 << 7))) + ((si4 & si5) ^ (~si4 & si6)) + cache[j] + buf[j];
			uint t2 = (((si0 >> 2) | (si0 << 30)) ^ ((si0 >> 13) | (si0 << 19)) ^ ((si0 >> 22) | (si0 << 10)));
			t2 = t2 + ((si0 & si1) ^ (si0 & si2) ^ (si1 & si2));
			si7 = si6;
			si6 = si5;
			si5 = si4;
			si4 = si3 + t1;
			si3 = si2;
			si2 = si1;
			si1 = si0;
			si0 = t1 + t2;
		}
		s0 += si0; s1 += si1; s2 += si2; s3 += si3;
		s4 += si4; s5 += si5; s6 += si6; s7 += si7;
	}

	global_state[0] = s0; global_state[1] = s1; global_state[2] = s2; global_state[3] = s3;
	global_state[4] = s4; global_state[5] = s5; global_state[6] = s6; global_state[7] = s7;
}
