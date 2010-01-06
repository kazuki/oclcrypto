#define ROTATE_UINT4(x,s) (((x) << (uint4)(s)) | ((x) >> (uint4)(32 - (s))))

__kernel 
void encrypt1 (const __global uint4* input,
              __global   uint4* output,
              const __global uint4 key[11],
              const __global uint global_T0[256],
              const __global uint global_sbox[256],
              __local uint T0[256],
              __local uint sbox[256]
)
{
	size_t global_id = get_global_id(0);
	size_t local_id = get_local_id(0);
	size_t local_size = get_local_size(0);
	size_t t0_copy_size = 256 / local_size;
	if (t0_copy_size == 0) t0_copy_size = 1;
	size_t t0_copy_offset = local_id * t0_copy_size;
	const uint4 shift_8 = (uint4)(8);
	const uint4 mask_0 = (uint4)(0x00ff00ff);
	const uint4 mask_1 = (uint4)(0xff00ff00);
	uint4 t0, t1;

	for (uint i = 0; i < t0_copy_size; i ++) {
		T0[t0_copy_offset + i] = global_T0[t0_copy_offset + i];
		sbox[t0_copy_offset + i] = global_sbox[t0_copy_offset + i];
	}
	barrier (CLK_LOCAL_MEM_FENCE);
	
	t1 = input[global_id];
	t0 = ((ROTATE_UINT4(t1, 8) & mask_0) | (ROTATE_UINT4(t1, 24) & mask_1)) ^ key[0];

	for (int i = 1; i <= 9; i ++) {
		t1 = (uint4)(T0[t0.s3 & 0xff], T0[t0.s0 & 0xff], T0[t0.s1 & 0xff], T0[t0.s2 & 0xff]);
		t0 = t0 >> shift_8;
		t1 = ROTATE_UINT4(t1, 24);
		t1 ^= (uint4)(T0[t0.s2 & 0xff], T0[t0.s3 & 0xff], T0[t0.s0 & 0xff], T0[t0.s1 & 0xff]);
		t0 = t0 >> shift_8;
		t1 = ROTATE_UINT4(t1, 24);
		t1 ^= (uint4)(T0[t0.s1 & 0xff], T0[t0.s2 & 0xff], T0[t0.s3 & 0xff], T0[t0.s0 & 0xff]);
		t0 = t0 >> shift_8;
		t1 = ROTATE_UINT4(t1, 24);
		t0 = t1 ^ (uint4)(T0[t0.s0], T0[t0.s1], T0[t0.s2], T0[t0.s3]) ^ key[i];
	}

	t1 = (uint4)(sbox[t0.s3 & 0xff], sbox[t0.s0 & 0xff], sbox[t0.s1 & 0xff], sbox[t0.s2 & 0xff]) << shift_8;
	t0 = t0 >> shift_8;
	t1 = (t1 | (uint4)(sbox[t0.s2 & 0xff], sbox[t0.s3 & 0xff], sbox[t0.s0 & 0xff], sbox[t0.s1 & 0xff])) << shift_8;
	t0 = t0 >> shift_8;
	t1 = (t1 | (uint4)(sbox[t0.s1 & 0xff], sbox[t0.s2 & 0xff], sbox[t0.s3 & 0xff], sbox[t0.s0 & 0xff])) << shift_8;
	t0 = t0 >> shift_8;
	output[global_id] = (t1 | (uint4)(sbox[t0.s0], sbox[t0.s1], sbox[t0.s2], sbox[t0.s3])) ^ key[10];
}

__kernel 
void encrypt2 (const __global uint4* input,
              __global   uint4* output,
              const __global uint4 key[11],
              const __global uint global_T0[256],
              const __global uint global_T1[256],
              const __global uint global_T2[256],
              const __global uint global_T3[256],
              const __global uint global_sbox[256],
              __local uint T0[256],
              __local uint T1[256],
              __local uint T2[256],
              __local uint T3[256],
              __local uint sbox[256]
)
{
	size_t global_id = get_global_id(0);
	size_t global_size = get_global_size(0);
	size_t local_id = get_local_id(0);
	size_t local_size = get_local_size(0);
	size_t t0_copy_size = 256 / local_size;
	if (t0_copy_size == 0) t0_copy_size = 1;
	size_t t0_copy_offset = local_id * t0_copy_size;
	const uint4 shift_8 = (uint4)(8);
	const uint4 mask_0 = (uint4)(0x00ff00ff);
	const uint4 mask_1 = (uint4)(0xff00ff00);
	uint4 t0, t1;

	if (local_id < 256) {
		for (uint i = 0; i < t0_copy_size; i ++) {
			T0[t0_copy_offset + i] = global_T0[t0_copy_offset + i];
			T1[t0_copy_offset + i] = global_T1[t0_copy_offset + i];
			T2[t0_copy_offset + i] = global_T2[t0_copy_offset + i];
			T3[t0_copy_offset + i] = global_T3[t0_copy_offset + i];
			sbox[t0_copy_offset + i] = global_sbox[t0_copy_offset + i];
		}
	}
	barrier (CLK_LOCAL_MEM_FENCE);
	
	t1 = input[global_id];
	t0 = ((ROTATE_UINT4(t1, 8) & mask_0) | (ROTATE_UINT4(t1, 24) & mask_1)) ^ key[0];

	for (int i = 1; i <= 9; i ++) {
		t1 = (uint4)(T3[t0.s3 & 0xff], T3[t0.s0 & 0xff], T3[t0.s1 & 0xff], T3[t0.s2 & 0xff]);
		t0 = t0 >> shift_8;
		t1 ^= (uint4)(T2[t0.s2 & 0xff], T2[t0.s3 & 0xff], T2[t0.s0 & 0xff], T2[t0.s1 & 0xff]);
		t0 = t0 >> shift_8;
		t1 ^= (uint4)(T1[t0.s1 & 0xff], T1[t0.s2 & 0xff], T1[t0.s3 & 0xff], T1[t0.s0 & 0xff]);
		t0 = t0 >> shift_8;
		t0 = t1 ^ (uint4)(T0[t0.s0], T0[t0.s1], T0[t0.s2], T0[t0.s3]) ^ key[i];
	}

	t1 = (uint4)(sbox[t0.s3 & 0xff], sbox[t0.s0 & 0xff], sbox[t0.s1 & 0xff], sbox[t0.s2 & 0xff]) << shift_8;
	t0 = t0 >> shift_8;
	t1 = (t1 | (uint4)(sbox[t0.s2 & 0xff], sbox[t0.s3 & 0xff], sbox[t0.s0 & 0xff], sbox[t0.s1 & 0xff])) << shift_8;
	t0 = t0 >> shift_8;
	t1 = (t1 | (uint4)(sbox[t0.s1 & 0xff], sbox[t0.s2 & 0xff], sbox[t0.s3 & 0xff], sbox[t0.s0 & 0xff])) << shift_8;
	t0 = t0 >> shift_8;
	output[global_id] = (t1 | (uint4)(sbox[t0.s0], sbox[t0.s1], sbox[t0.s2], sbox[t0.s3])) ^ key[10];
}

__kernel 
void encrypt3 (const __global uint4* input,
              __global   uint4* output,
              const __global uint4 key[11],
              const __global uint global_T0[256],
              const __global uint global_T1[256],
              const __global uint global_T2[256],
              const __global uint global_T3[256],
              const __global uint global_sbox[256],
              __local uint T0[256],
              __local uint T1[256],
              __local uint T2[256],
              __local uint T3[256],
              __local uint sbox[256],
              uint total_blocks
)
{
	size_t global_id = get_global_id(0);
	size_t global_size = get_global_size(0);
	size_t local_id = get_local_id(0);
	size_t local_size = get_local_size(0);
	size_t t0_copy_size = 256 / local_size;
	if (t0_copy_size == 0) t0_copy_size = 1;
	size_t t0_copy_offset = local_id * t0_copy_size;
	const uint4 shift_8 = (uint4)(8);
	const uint4 mask_0 = (uint4)(0x00ff00ff);
	const uint4 mask_1 = (uint4)(0xff00ff00);
	uint4 t0, t1;

	if (local_id < 256) {
		for (uint i = 0; i < t0_copy_size; i ++) {
			T0[t0_copy_offset + i] = global_T0[t0_copy_offset + i];
			T1[t0_copy_offset + i] = global_T1[t0_copy_offset + i];
			T2[t0_copy_offset + i] = global_T2[t0_copy_offset + i];
			T3[t0_copy_offset + i] = global_T3[t0_copy_offset + i];
			sbox[t0_copy_offset + i] = global_sbox[t0_copy_offset + i];
		}
	}
	barrier (CLK_LOCAL_MEM_FENCE);

	for (uint block_idx = global_id; block_idx < total_blocks; block_idx += global_size) {
		t1 = input[block_idx];
		t0 = ((ROTATE_UINT4(t1, 8) & mask_0) | (ROTATE_UINT4(t1, 24) & mask_1)) ^ key[0];

		for (int i = 1; i <= 9; i ++) {
			t1 = (uint4)(T3[t0.s3 & 0xff], T3[t0.s0 & 0xff], T3[t0.s1 & 0xff], T3[t0.s2 & 0xff]);
			t0 = t0 >> shift_8;
			t1 ^= (uint4)(T2[t0.s2 & 0xff], T2[t0.s3 & 0xff], T2[t0.s0 & 0xff], T2[t0.s1 & 0xff]);
			t0 = t0 >> shift_8;
			t1 ^= (uint4)(T1[t0.s1 & 0xff], T1[t0.s2 & 0xff], T1[t0.s3 & 0xff], T1[t0.s0 & 0xff]);
			t0 = t0 >> shift_8;
			t0 = t1 ^ (uint4)(T0[t0.s0], T0[t0.s1], T0[t0.s2], T0[t0.s3]) ^ key[i];
		}

		t1 = (uint4)(sbox[t0.s3 & 0xff], sbox[t0.s0 & 0xff], sbox[t0.s1 & 0xff], sbox[t0.s2 & 0xff]) << shift_8;
		t0 = t0 >> shift_8;
		t1 = (t1 | (uint4)(sbox[t0.s2 & 0xff], sbox[t0.s3 & 0xff], sbox[t0.s0 & 0xff], sbox[t0.s1 & 0xff])) << shift_8;
		t0 = t0 >> shift_8;
		t1 = (t1 | (uint4)(sbox[t0.s1 & 0xff], sbox[t0.s2 & 0xff], sbox[t0.s3 & 0xff], sbox[t0.s0 & 0xff])) << shift_8;
		t0 = t0 >> shift_8;
		output[block_idx] = (t1 | (uint4)(sbox[t0.s0], sbox[t0.s1], sbox[t0.s2], sbox[t0.s3])) ^ key[10];
	}
}

#if 0
// NVIDIA DRIVER BUG.
__kernel 
void encrypt4 (const __global uint* input,
              __global   uint* output,
              const __global uint key[44],
              const __global uint global_T0[256],
              const __global uint global_T1[256],
              const __global uint global_T2[256],
              const __global uint global_T3[256],
              const __global uint global_sbox[256],
              __local uint T0[256],
              __local uint T1[256],
              __local uint T2[256],
              __local uint T3[256],
              __local uint sbox[256],
              __local uint* state,
              uint total_blocks
)
{
	size_t global_id = (get_global_id(0) >> 2) << 2;
	size_t global_size = get_global_size(0);
	size_t local_id = get_local_id(0);
	size_t id = local_id & 3;
	size_t idp1 = (id + 1) & 3, idp2 = (id + 2) & 3, idp3 = (id + 3) & 3;
	size_t local_size = get_local_size(0);
	size_t t0_copy_size = 256 / local_size;
	if (t0_copy_size == 0) t0_copy_size = 1;
	size_t t0_copy_offset = local_id * t0_copy_size;
	__local uint *state2;
	uint tmp;

	state += (local_id >> 2) << 3;
	state2 = state + 4;
	total_blocks <<= 2;
	if (local_id < 256) {
		for (uint i = 0; i < t0_copy_size; i ++) {
			T0[t0_copy_offset + i] = global_T0[t0_copy_offset + i];
			T1[t0_copy_offset + i] = global_T1[t0_copy_offset + i];
			T2[t0_copy_offset + i] = global_T2[t0_copy_offset + i];
			T3[t0_copy_offset + i] = global_T3[t0_copy_offset + i];
			sbox[t0_copy_offset + i] = global_sbox[t0_copy_offset + i];
		}
	}
	barrier (CLK_LOCAL_MEM_FENCE);

	for (uint block_idx = global_id; block_idx < total_blocks; block_idx += global_size) {
		tmp = input[block_idx + id];
		state[id] = ((((tmp << 8) | (tmp >> 24)) & 0x00ff00ff) | (((tmp << 24) | (tmp >> 8)) & 0xff00ff00)) ^ key[id];
		barrier (CLK_LOCAL_MEM_FENCE);

		for (int i = 1; i <= 8; i += 2) {
			state2[id] = T0[state[id] >> 24] ^ T1[(state[idp1] >> 16) & 0xff] ^
			  T2[(state[idp2] >> 8) & 0xff] ^ T3[state[idp3] & 0xff] ^ key[i * 4 + id];
			barrier (CLK_LOCAL_MEM_FENCE);
			state[id] = T0[state2[id] >> 24] ^ T1[(state2[idp1] >> 16) & 0xff] ^
			  T2[(state2[idp2] >> 8) & 0xff] ^ T3[state2[idp3] & 0xff] ^ key[i * 4 + 4 + id];
			barrier (CLK_LOCAL_MEM_FENCE);
		}
		state2[id] = T0[state[id] >> 24] ^ T1[(state[idp1] >> 16) & 0xff] ^
			T2[(state[idp2] >> 8) & 0xff] ^ T3[state[idp3] & 0xff] ^ key[36 + id];
		barrier (CLK_LOCAL_MEM_FENCE);
		output[block_idx + id] = 
			(sbox[state2[id] >> 24] |
			 (sbox[(state2[idp1] >> 16) & 0xff] << 8) |
			 (sbox[(state2[idp2] >> 8) & 0xff] << 16) |
			 (sbox[state2[idp3] & 0xff] << 24)) ^ key[40 + id];
	}
}
#endif
