#define ROTATE_UINT4(x,s) ((x << (uint4)(s)) | (x >> (uint4)(32 - s)))

uint8 subcrumb (uint8 x)
{
	/* TODO: OPTIMIZE for GPU */
	uint2 r4 = x.s05;
	uint2 r1 = x.s16;
	uint2 r0 = r4 | r1;
	uint2 r3 = x.s34;
	uint2 r2 = x.s27 ^ r3;
	r1 = ~r1;
	r0 ^= r3; r3 &= r4; r1 ^= r3; r3 ^= r2;
	r2 &= r0; r0 = ~r0; r2 ^= r1; r1 |= r3;

	x.s05 = r4 ^ r1;
	x.s34 = r3 ^ r2;
	x.s27 = r2 & r1;
	x.s16 = r1 ^ r0;
	return x;
}

uint8 mixWord (uint8 x)
{
	uint4 s0 = x.s0123;
	uint4 s1 = x.s4567 ^ s0;
	s0 = ROTATE_UINT4 (s0, 2) ^ s1;
	s1 = ROTATE_UINT4 (s1, 14) ^ s0;
	s0 = ROTATE_UINT4 (s0, 10) ^ s1;
	s1 = ROTATE_UINT4 (s1, 1);
	return (uint8)(s0, s1);
}

uint8 permutation (uint8 x, __local uint* consts)
{
	for (int i = 0; i < 8; i ++) {
		x = subcrumb (x);
		x = mixWord (x);
		x.s0 ^= consts[i * 2];
		x.s4 ^= consts[i * 2 + 1];
	}
	return x;
}

uint8 mul2 (uint8 x)
{
	return (uint8)(x.s7, x.s0 ^ x.s7, x.s1, x.s2 ^ x.s7, x.s3 ^ x.s7, x.s4, x.s5, x.s6);
}

__kernel void core256_parallel
(
 const __global uint8 *input,
 __global uint8 *state,
 const __global uint *consts,
 __local uint *cache1,
 uint blocks,
 __local uint8 *local_state
)
{
	int parallel_index = get_global_id (0) >> 2;
	int parallels = get_global_size (0) >> 2;
	int local_id = get_local_id (0);
	int id = local_id & 3;
	state += parallel_index * 3;
	local_state += (local_id >> 2) * 3;
	if (local_id <= 3) {
		for (int i = 0; i < 12; i ++)
			cache1[id * 12 + i] = consts[id * 12 + i];
	}
	if (id < 3)
		local_state[id] = state[id];

	/* 256bit Message */
	for (uint i = 0; i < blocks; i ++) {
		barrier (CLK_LOCAL_MEM_FENCE);
		if (id < 3) {
			uint8 m = input[parallels * i + parallel_index];
			m = (m >> (uint8)(24)) | ((m >> (uint8)(8)) & (uint8)(0xff00))
				| ((m << (uint8)(8)) & (uint8)(0xff0000)) | (m << (uint8)(24));
			uint8 s0 = local_state[0], s1 = local_state[1], s2 = local_state[2];
			uint8 si = local_state[id];
			uint8 t = mul2 (s0 ^ s1 ^ s2);
			switch (id) {
			case 1:
				m = mul2 (m);
				break;
			case 2:
				m = (uint8)(m.s6, m.s6 ^ m.s7, m.s0 ^ m.s7, m.s1 ^ m.s6, m.s2 ^ m.s6 ^ m.s7, m.s3 ^ m.s7, m.s4, m.s5);
				break;
			}
			si ^= t ^ m;
			si = (si << (uint8)(0,0,0,0,id,id,id,id)) | (si >> (uint8)(32,32,32,32,32-id,32-id,32-id,32-id));
			local_state[id] = permutation (si, cache1 + id * 16);
		}
	}

	/* Update State */
	if (id < 3)
		state[id] = local_state[id];
}

__kernel void core256_serial
(
 const __global uint8 *input,
 __global uint8 *global_state,
 const __global uint *consts,
 __local uint *cache1,
 uint blocks
)
{
	uint8 m,s0,s1,s2;
	uint i, parallel_index = get_global_id (0);
	uint parallels = get_global_size (0);

	if (get_local_id(0) == 0) {
		for (int i = 0; i < 48; i ++)
			cache1[i] = consts[i];
	}
	barrier (CLK_LOCAL_MEM_FENCE);
	s0 = global_state[parallel_index * 3 + 0];
	s1 = global_state[parallel_index * 3 + 1];
	s2 = global_state[parallel_index * 3 + 2];

	/* 256bit Message */
	for (i = 0; i < blocks; i ++) {
		m = mul2 (s0 ^ s1 ^ s2);
		s0 ^= m;
		s1 ^= m;
		s2 ^= m;
		
		m = input[parallels * i + parallel_index];
		m = (m >> (uint8)(24)) | ((m >> (uint8)(8)) & (uint8)(0xff00))
			| ((m << (uint8)(8)) & (uint8)(0xff0000)) | (m << (uint8)(24));
		s0 ^= m;
		m = mul2 (m);
		s1 ^= m;
		s2 ^= mul2 (m);
		s1 = (s1 << (uint8)(0,0,0,0,1,1,1,1)) | (s1 >> (uint8)(32,32,32,32,31,31,31,31));
		s2 = (s2 << (uint8)(0,0,0,0,2,2,2,2)) | (s2 >> (uint8)(32,32,32,32,30,30,30,30));
		s0 = permutation (s0, cache1);
		s1 = permutation (s1, cache1 + 16);
		s2 = permutation (s2, cache1 + 32);
	}

	/* Update State */
	global_state[parallel_index * 3 + 0] = s0;
	global_state[parallel_index * 3 + 1] = s1;
	global_state[parallel_index * 3 + 2] = s2;
}
