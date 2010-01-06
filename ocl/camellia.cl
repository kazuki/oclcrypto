#define ROTATE_UINT2(x,s) (((x) << (uint2)(s)) | ((x) >> (uint2)(32 - s)))
#define ROTATE_UINT4(x,s) (((x) << (uint4)(s)) | ((x) >> (uint4)(32 - s)))

__kernel 
void encrypt1 (const __global uint4* input,
              __global   uint4* output,
              const __global uint2* constant_key,
              const __global uint* global_sbox1,
              const __global uint* global_sbox2,
              const __global uint* global_sbox3,
              const __global uint* global_sbox4,
              __local uint* sbox1,
              __local uint* sbox2,
              __local uint* sbox3,
              __local uint* sbox4,
              uint total_blocks
)
{
	size_t global_id = get_global_id(0);
	size_t global_size = get_global_size(0);
	size_t local_id = get_local_id(0);
	size_t local_size = get_local_size(0);
	size_t copy_size = 256 / local_size;
	if (copy_size == 0) copy_size = 1;
	size_t copy_offset = local_id * copy_size;
	const uint2 shift1 = (uint2)(1);
	const uint2 shift8_uint2 = (uint2)(8);
	const uint2 mask_notfe = (uint2)(~0xfefefefe);
	const uint2 mask_fe = (uint2)(0xfefefefe);
	uint4 t0;
	uint2 x0, x1, s, u;

	if (local_id < 256) {
		for (uint i = 0; i < copy_size; i ++) {
			sbox1[copy_offset + i] = global_sbox1[copy_offset + i];
			sbox2[copy_offset + i] = global_sbox2[copy_offset + i];
			sbox3[copy_offset + i] = global_sbox3[copy_offset + i];
			sbox4[copy_offset + i] = global_sbox4[copy_offset + i];
		}
	}
	barrier (CLK_LOCAL_MEM_FENCE);

	for (uint block_idx = global_id; block_idx < total_blocks; block_idx += global_size) {
		const __global uint2 *key = constant_key;
		t0 = input[block_idx];
		x0 = t0.s01 ^ key[0];
		x1 = t0.s23 ^ key[1];
		key += 2;

		for (int l = 0;; l ++) {
			for (uint i = 0; i < 3; i ++) {
				s = x0 ^ key[0];
				u = (uint2)(sbox1[s.s0 & 0xff], sbox2[s.s1 & 0xff]);
				s = s >> shift8_uint2;
				u ^= (uint2)(sbox2[s.s0 & 0xff], sbox3[s.s1 & 0xff]);
				s = s >> shift8_uint2;
				u ^= (uint2)(sbox3[s.s0 & 0xff], sbox4[s.s1 & 0xff]);
				s = s >> shift8_uint2;
				u ^= (uint2)(sbox4[s.s0], sbox1[s.s1]);
				x1 ^= (uint2)(u.s0 ^ u.s1, u.s0 ^ u.s1 ^ ((u.s0 << 8) | (u.s0 >> 24)));
				
				s = x1 ^ key[1];
				u = (uint2)(sbox1[s.s0 & 0xff], sbox2[s.s1 & 0xff]);
				s = s >> shift8_uint2;
				u ^= (uint2)(sbox2[s.s0 & 0xff], sbox3[s.s1 & 0xff]);
				s = s >> shift8_uint2;
				u ^= (uint2)(sbox3[s.s0 & 0xff], sbox4[s.s1 & 0xff]);
				s = s >> shift8_uint2;
				u ^= (uint2)(sbox4[s.s0 & 0xff], sbox1[s.s1 & 0xff]);
				x0 ^= (uint2)(u.s0 ^ u.s1, u.s0 ^ u.s1 ^ ((u.s0 << 8) | (u.s0 >> 24)));
				key += 2;
			}
			if (l == 2)
				break;
			
			x1.s0 ^= x1.s1 | key[1].s1;
			u = (uint2)(x0.s0 & key[0].s0, x1.s0 & key[1].s0);
			u = ((u << shift1) & mask_fe) | (ROTATE_UINT2(u, 17) & mask_notfe);
			x0.s1 ^= u.s0;
			x0.s0 ^= x0.s1 | key[0].s1;
			x1.s1 ^= u.s1;
			key += 2;
		}

		x0 ^= key[1];
		x1 ^= key[0];
		output[block_idx] = (uint4)(x1.s0, x1.s1, x0.s0, x0.s1);
	}
}

__kernel 
void encrypt2 (const __global uint16* input,
              __global   uint16* output,
              const __global uint* constant_key,
              const __global uint global_sbox1[256],
              const __global uint global_sbox2[256],
              const __global uint global_sbox3[256],
              const __global uint global_sbox4[256],
              __local uint sbox1[256],
              __local uint sbox2[256],
              __local uint sbox3[256],
              __local uint sbox4[256],
              uint total_blocks
)
{
	const uint4 shift_1 = (uint4)(1);
	const uint4 shift_8 = (uint4)(8);
	const uint4 mask_fe = (uint4)(0xfefefefe);
	const uint4 mask_notfe = (uint4)(~0xfefefefe);
	size_t global_id = get_global_id(0);
	size_t global_size = get_global_size(0);
	size_t local_id = get_local_id(0);
	size_t copy_size = 256 / get_local_size(0);
	if (copy_size == 0) copy_size = 1;
	size_t copy_offset = local_id * copy_size;
	uint16 t0;
	uint4 x0, x1, x2, x3, s0, s1, u, d;
	total_blocks >>= 2;

	if (local_id < 256) {
		for (uint i = 0; i < copy_size; i ++) {
			sbox1[copy_offset + i] = global_sbox1[copy_offset + i];
			sbox2[copy_offset + i] = global_sbox2[copy_offset + i];
			sbox3[copy_offset + i] = global_sbox3[copy_offset + i];
			sbox4[copy_offset + i] = global_sbox4[copy_offset + i];
		}
	}
	barrier (CLK_LOCAL_MEM_FENCE);

	for (uint block_idx = global_id; block_idx < total_blocks; block_idx += global_size) {
		const __global uint *key = constant_key;
		t0 = input[block_idx];
		x0 = (uint4)(t0.s0, t0.s4, t0.s8, t0.sc) ^ key[0];
		x1 = (uint4)(t0.s1, t0.s5, t0.s9, t0.sd) ^ key[1];
		x2 = (uint4)(t0.s2, t0.s6, t0.sa, t0.se) ^ key[2];
		x3 = (uint4)(t0.s3, t0.s7, t0.sb, t0.sf) ^ key[3];
		key += 4;

		for (int l = 0;; l ++) {
			for (uint i = 0; i < 3; i ++) {
				s0 = x0 ^ key[0];
				s1 = x1 ^ key[1];
				u = (uint4)(sbox1[s0.s0 & 0xff], sbox1[s0.s1 & 0xff], sbox1[s0.s2 & 0xff], sbox1[s0.s3 & 0xff]);
				d = (uint4)(sbox2[s1.s0 & 0xff], sbox2[s1.s1 & 0xff], sbox2[s1.s2 & 0xff], sbox2[s1.s3 & 0xff]);
				s0 = s0 >> shift_8;
				s1 = s1 >> shift_8;
				u ^= (uint4)(sbox2[s0.s0 & 0xff], sbox2[s0.s1 & 0xff], sbox2[s0.s2 & 0xff], sbox2[s0.s3 & 0xff]);
				d ^= (uint4)(sbox3[s1.s0 & 0xff], sbox3[s1.s1 & 0xff], sbox3[s1.s2 & 0xff], sbox3[s1.s3 & 0xff]);
				s0 = s0 >> shift_8;
				s1 = s1 >> shift_8;
				u ^= (uint4)(sbox3[s0.s0 & 0xff], sbox3[s0.s1 & 0xff], sbox3[s0.s2 & 0xff], sbox3[s0.s3 & 0xff]);
				d ^= (uint4)(sbox4[s1.s0 & 0xff], sbox4[s1.s1 & 0xff], sbox4[s1.s2 & 0xff], sbox4[s1.s3 & 0xff]);
				s0 = s0 >> shift_8;
				s1 = s1 >> shift_8;
				u ^= (uint4)(sbox4[s0.s0], sbox4[s0.s1], sbox4[s0.s2], sbox4[s0.s3]);
				d ^= (uint4)(sbox1[s1.s0], sbox1[s1.s1], sbox1[s1.s2], sbox1[s1.s3]);
				d ^= u;
				x2 ^= d;
				x3 ^= d ^ ROTATE_UINT4(u, 8);

				s0 = x2 ^ key[2];
				s1 = x3 ^ key[3];
				u = (uint4)(sbox1[s0.s0 & 0xff], sbox1[s0.s1 & 0xff], sbox1[s0.s2 & 0xff], sbox1[s0.s3 & 0xff]);
				d = (uint4)(sbox2[s1.s0 & 0xff], sbox2[s1.s1 & 0xff], sbox2[s1.s2 & 0xff], sbox2[s1.s3 & 0xff]);
				s0 = s0 >> shift_8;
				s1 = s1 >> shift_8;
				u ^= (uint4)(sbox2[s0.s0 & 0xff], sbox2[s0.s1 & 0xff], sbox2[s0.s2 & 0xff], sbox2[s0.s3 & 0xff]);
				d ^= (uint4)(sbox3[s1.s0 & 0xff], sbox3[s1.s1 & 0xff], sbox3[s1.s2 & 0xff], sbox3[s1.s3 & 0xff]);
				s0 = s0 >> shift_8;
				s1 = s1 >> shift_8;
				u ^= (uint4)(sbox3[s0.s0 & 0xff], sbox3[s0.s1 & 0xff], sbox3[s0.s2 & 0xff], sbox3[s0.s3 & 0xff]);
				d ^= (uint4)(sbox4[s1.s0 & 0xff], sbox4[s1.s1 & 0xff], sbox4[s1.s2 & 0xff], sbox4[s1.s3 & 0xff]);
				s0 = s0 >> shift_8;
				s1 = s1 >> shift_8;
				u ^= (uint4)(sbox4[s0.s0], sbox4[s0.s1], sbox4[s0.s2], sbox4[s0.s3]);
				d ^= (uint4)(sbox1[s1.s0], sbox1[s1.s1], sbox1[s1.s2], sbox1[s1.s3]);
				d ^= u;
				x0 ^= d;
				x1 ^= d ^ ROTATE_UINT4(u, 8);
				key += 4;
			}
			if (l == 2)
				break;

			u = x0 & key[0];
			x1 ^= ((u << shift_1) & mask_fe) | (ROTATE_UINT4(u, 17) & mask_notfe);
			x0 ^= x1 | key[1];
			x2 ^= x3 | key[3];
			u = x2 & key[2];
			x3 ^= ((u << shift_1) & mask_fe) | (ROTATE_UINT4(u, 17) & mask_notfe);
			key += 4;
		}

		x2 ^= key[0];
		x3 ^= key[1];
		x0 ^= key[2];
		x1 ^= key[3];
		output[block_idx] = (uint16)(x2.s0, x3.s0, x0.s0, x1.s0,
											  x2.s1, x3.s1, x0.s1, x1.s1,
											  x2.s2, x3.s2, x0.s2, x1.s2,
											  x2.s3, x3.s3, x0.s3, x1.s3);
	}
}
