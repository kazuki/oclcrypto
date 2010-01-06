using System;
using System.Collections.Generic;
using System.Diagnostics;
using openCL;
using CLProgram = openCL.Program;

namespace oclCrypto
{
	class Program
	{
		static void Main ()
		{
			LuffaTest ();
			//AESTest ();
			//CamelliaTest ();
			//AESTest2 ();
			//CamelliaTest2 ();
			//for (int i = 1; i <= 8192; i *= 2)
			//SHATest (0);
			//ECCTest ();
		}

		static void LuffaTest ()
		{
			const int memTests = 1;
			const int updateTests = 1;
			const bool UseParallelMode = true;
			TimeSpan total = TimeSpan.Zero;
			int parallels;
			int blocks_per_instance = 1024;
			byte[] input, state, state_ref;

			using (Context context = new Context (DeviceType.GPU))
			using (CommandQueue queue = context.CreateCommandQueue (context.Devices[0], CommandQueueProperties.Default)) {
				int local_size = (int)queue.Device.MaxWorkItemSizes[0];
				parallels = local_size * (int)queue.Device.MaxComputeUnits;
				if (UseParallelMode) parallels /= 4;
				input = new byte[Luffa.MessageSize * parallels * blocks_per_instance];
				state = new byte[parallels * Luffa.StateSize];
				state_ref = new byte[parallels * Luffa.StateSize];
				new Random ().NextBytes (input);

				// balance
				if (parallels < local_size) {
					local_size = parallels / (int)queue.Device.MaxComputeUnits;
					local_size = (int)Math.Pow (2, Math.Ceiling (Math.Log (local_size, 2)));
					if (UseParallelMode) {
						if (local_size <= 4)
							local_size = 4;
					} else {
						if (local_size <= 0)
							local_size = 1;
					}
				}

				using (CLProgram prog = context.CreateProgram (OclCodeStore.GetOclCode ("luffa"), context.Devices, null))
				using (Memory inMem = context.CreateBuffer (MemoryFlags.ReadOnly, input.Length))
				using (Memory stateMem = context.CreateBuffer (MemoryFlags.ReadWrite, state.Length))
				using (Memory constMem = context.CreateBuffer (MemoryFlags.ReadOnly, 4 * Luffa.InitValues.Length))
				using (Kernel kernel = prog.CreateKernel ("core256_" + (UseParallelMode ? "parallel" : "serial"))) {
					// Copy constant values
					queue.WriteBuffer (constMem, 0, Luffa.InitValues, 0, Luffa.InitValues.Length * 4);

					// Init State
					uint[] temp = new uint[parallels * Luffa.StateSize / 4];
					for (int i = 0; i < parallels; i++) {
						for (int j = 0; j < 24; j++)
							temp[i * 24 + j] = Luffa.StartingValues[j];
					}
					queue.WriteBuffer (stateMem, 0, temp, 0, temp.Length * 4);

					int global_size = parallels;
					if (UseParallelMode)
						global_size *= 4;
					int max_local_size = (UseParallelMode ? (int)(queue.Device.LocalMemSize / 2) / (Luffa.StateSize / 4) : local_size);
					while (local_size > global_size || local_size > max_local_size)
						local_size >>= 1;

					// Setup Kernel Arguments
					kernel.SetArgument (0, inMem);
					kernel.SetArgument (1, stateMem);
					kernel.SetArgument (2, constMem);
					kernel.SetLocalDataShare (3, 4 * Luffa.InitValues.Length);
					kernel.SetArgument (4, blocks_per_instance, 4);
					if (UseParallelMode)
						kernel.SetLocalDataShare (5, local_size * Luffa.StateSize / 4);

					total += Execute ("write", memTests, input.Length, delegate () {
						queue.WriteBuffer (inMem, 0, input, 0, input.Length);
					});

					total += Execute ("kernel", updateTests, input.Length, delegate () {
						queue.Execute (kernel, 0, global_size, local_size);
					});

					total += Execute ("read", memTests, state.Length, delegate () {
						queue.ReadBuffer (stateMem, 0, state, 0, state.Length);
					});
					WriteTime ("total", total, input.Length);
				}
			}

#if false
			Luffa.InitState (state_ref);
			for (int i = 0; i < blocks_per_instance; i ++) {
				Luffa.Update (input, i * Luffa.MessageSize * parallels, Luffa.MessageSize * parallels, state_ref);
			}
			for (int i = 0; i < state.Length; i++) {
				if (state[i] != state_ref[i]) {
					Console.ForegroundColor = ConsoleColor.Red;
					Console.WriteLine ("err");
					Console.ForegroundColor = ConsoleColor.White;
					break;
				}
			}
#endif
			Console.WriteLine ("cmpl");
			Console.ReadLine ();
		}

		static void SHATest (int parallels)
		{
			const int memTests = 100;
			const int updateTests = 100;
			TimeSpan total = TimeSpan.Zero;
			//int parallels;
			int blocks_per_instance = 1024;
			byte[] input, state, state_ref;

			using (Context context = new Context (DeviceType.GPU))
			using (CommandQueue queue = context.CreateCommandQueue (context.Devices[0], CommandQueueProperties.Default)) {
				int local_size = (int)queue.Device.MaxWorkItemSizes[0] / 2;
				parallels = local_size * (int)queue.Device.MaxComputeUnits;
				input = new byte[SHA256.MessageSize * parallels * blocks_per_instance];
				state = new byte[parallels * SHA256.StateSize];
				state_ref = new byte[parallels * SHA256.StateSize];
				new Random ().NextBytes (input);

				// balance
				if (parallels < local_size) {
					local_size = parallels / (int)queue.Device.MaxComputeUnits;
					local_size = (int)Math.Pow (2, Math.Ceiling (Math.Log (local_size, 2)));
					if (local_size <= 0)
						local_size = 1;
				}

				using (CLProgram prog = context.CreateProgram (OclCodeStore.GetOclCode ("sha-256"), context.Devices, null))
				using (Memory inMem = context.CreateBuffer (MemoryFlags.ReadOnly, input.Length))
				using (Memory stateMem = context.CreateBuffer (MemoryFlags.ReadWrite, state.Length))
				using (Memory constMem = context.CreateBuffer (MemoryFlags.ReadOnly, 4 * SHA256.Constants.Length))
				using (Kernel kernel = prog.CreateKernel ("core256")) {
					// Copy constant values
					queue.WriteBuffer (constMem, 0, SHA256.Constants, 0, SHA256.Constants.Length * 4);

					// Init State
					uint[] temp = new uint[parallels * SHA256.StateSize / 4];
					for (int i = 0; i < parallels; i++) {
						for (int j = 0; j < SHA256.InitialValues.Length; j++)
							temp[i * SHA256.InitialValues.Length + j] = SHA256.InitialValues[j];
					}
					queue.WriteBuffer (stateMem, 0, temp, 0, temp.Length * 4);

					int global_size = parallels;
					int max_local_size = local_size;
					while (local_size > global_size || local_size > max_local_size)
						local_size >>= 1;

					// Setup Kernel Arguments
					kernel.SetArgument (0, inMem);
					kernel.SetArgument (1, stateMem);
					kernel.SetArgument (2, constMem);
					kernel.SetLocalDataShare (3, 4 * SHA256.Constants.Length);
					kernel.SetArgument (4, blocks_per_instance, 4);

					total += Execute ("write", memTests, input.Length, delegate () {
						queue.WriteBuffer (inMem, 0, input, 0, input.Length);
					});

					total += Execute ("kernel", updateTests, input.Length, delegate () {
						queue.Execute (kernel, 0, global_size, local_size);
					});

					total += Execute ("read", memTests, state.Length, delegate () {
						queue.ReadBuffer (stateMem, 0, state, 0, state.Length);
					});
					WriteTime ("total", total, input.Length);
				}
			}

#if false
			SHA256.InitState (state_ref);
			for (int i = 0; i < blocks_per_instance; i ++) {
				SHA256.Update (input, i * SHA256.MessageSize * parallels, SHA256.MessageSize * parallels, state_ref);
			}
			for (int i = 0; i < state.Length; i++) {
				if (state[i] != state_ref[i]) {
					Console.ForegroundColor = ConsoleColor.Red;
					Console.WriteLine ("err");
					Console.ForegroundColor = ConsoleColor.White;
					break;
				}
			}
#endif
			//Console.WriteLine ("cmpl");
			//Console.ReadLine ();
		}

		static void AESTest ()
		{
			const int memTests = 1;
			const int encryptTests = 1;
			byte[] key = new byte[16];
			byte[] input = new byte[1024 * 1024 * 64];
			byte[] output = new byte[input.Length];
			byte[] output_ref = new byte[input.Length];
			byte[] expandedKey;
			new Random ().NextBytes (key);
			new Random ().NextBytes (input);
			AES.KeyExpansion (key, out expandedKey);
			TimeSpan total = TimeSpan.Zero;

			using (Context context = new Context (DeviceType.GPU))
			using (CommandQueue queue = context.CreateCommandQueue (context.Devices[0], CommandQueueProperties.Default))
#if false
			using (CLProgram prog = context.CreateProgram (OclCodeStore.GetOclCode ("bitslice_aes2"), context.Devices, null))
			using (Memory mem = context.CreateBuffer (MemoryFlags.ReadWrite, input.Length))
			using (Memory keyMem = context.CreateBuffer (MemoryFlags.ReadWrite, expandedKey.Length * 32)) {

				using (Memory nonsliceKeyMem = context.CreateBuffer (MemoryFlags.WriteOnly, expandedKey.Length))
				using (Kernel kernel = prog.CreateKernel ("bitslice_key")) {
					kernel.SetArgument (0, nonsliceKeyMem);
					kernel.SetArgument (1, keyMem);
					queue.WriteBuffer (nonsliceKeyMem, 0, expandedKey, 0, expandedKey.Length);
					queue.Execute (kernel, 0, expandedKey.Length * 8 / 4, 8);
				}

				int global_size = input.Length / (16 * 32);
				int local_size = (int)queue.Device.LocalMemSize / 512 / 2;
				while (local_size > global_size)
					local_size >>= 1;

				total += Execute ("write", memTests, input.Length, delegate () {
					queue.WriteBuffer (mem, 0, input, 0, input.Length);
				});
#if false
				using (Kernel kernel_encrypt = prog.CreateKernel ("encrypt1")) {
					kernel_encrypt.SetArgument (0, mem);
					kernel_encrypt.SetArgument (1, keyMem);
					kernel_encrypt.SetLocalDataShare (2, 512 * local_size);

					total += Execute ("kernel(encrypt)", encryptTests, input.Length, delegate () {
						queue.Execute (kernel_encrypt, 0, global_size, local_size);
					});
				}
#else
				using (Kernel kernel_encrypt2 = prog.CreateKernel ("encrypt2"))
				using (Kernel kernel_bitslice = prog.CreateKernel ("bitslice_kernel")) {
					kernel_bitslice.SetArgument (0, mem);
					kernel_encrypt2.SetArgument (0, mem);
					kernel_encrypt2.SetArgument (1, keyMem);
					kernel_encrypt2.SetLocalDataShare (2, 512 * local_size);

#if true
					total += Execute ("kernel(bitslice)", encryptTests, input.Length, delegate () {
						queue.Execute (kernel_bitslice, 0, global_size, local_size);
					});
					total += Execute ("kernel(encrypt2)", encryptTests, input.Length, delegate () {
						queue.Execute (kernel_encrypt2, 0, global_size, local_size);
					});
					total += Execute ("kernel(unbitslice)", encryptTests, input.Length, delegate () {
						queue.Execute (kernel_bitslice, 0, global_size, local_size);
					});
#else
					total += Execute ("kernel", encryptTests, input.Length, delegate () {
						EventHandle bitslice_wait, encrypt_wait;
						queue.ExecuteAsync (kernel_bitslice, 0, global_size, local_size, out bitslice_wait);
						queue.ExecuteAsync (kernel_encrypt2, 0, global_size, local_size, new EventHandle[] { bitslice_wait }, out encrypt_wait);
						queue.Execute (kernel_bitslice, 0, global_size, local_size, new EventHandle[] { encrypt_wait });
					});
#endif
				}
#endif
				total += Execute ("read", memTests, input.Length, delegate () {
					queue.ReadBuffer (mem, 0, output, 0, output.Length);
				});
			}
#elif false
			using (CLProgram prog = context.CreateProgram (OclCodeStore.GetOclCode ("bitslice_aes"), context.Devices, null))
			using (Memory inMem = context.CreateBuffer (MemoryFlags.ReadWrite, input.Length))
			using (Memory keyMem = context.CreateBuffer (MemoryFlags.ReadWrite, expandedKey.Length * 32)) {

				using (Memory nonsliceKeyMem = context.CreateBuffer (MemoryFlags.ReadOnly, expandedKey.Length))
				using (Kernel kernel = prog.CreateKernel ("bitslice_key")) {
					kernel.SetArgument (0, nonsliceKeyMem);
					kernel.SetArgument (1, keyMem);
					queue.WriteBuffer (nonsliceKeyMem, 0, expandedKey, 0, expandedKey.Length);
					queue.Execute (kernel, 0, expandedKey.Length * 8, 128);
				}

				int global_size = input.Length / 16;
				int local_size = 128;

				total += Execute ("write", memTests, input.Length, delegate () {
					queue.WriteBuffer (inMem, 0, input, 0, input.Length);
				});

				using (Kernel kernel = prog.CreateKernel ("encrypt")) {
					kernel.SetArgument (0, inMem);
					kernel.SetArgument (1, keyMem);
					kernel.SetLocalDataShare (2, 16 * 128);
					kernel.SetLocalDataShare (3, 16 * 128);
					kernel.SetLocalDataShare (4, 16 * 128);

					total += Execute ("kernel(encrypt)", encryptTests, input.Length, delegate () {
						queue.Execute (kernel, 0, global_size, local_size);
					});
				}

				total += Execute ("read", memTests, input.Length, delegate () {
					queue.ReadBuffer (inMem, 0, output, 0, output.Length);
				});
			}
#else
			using (CLProgram prog = context.CreateProgram (OclCodeStore.GetOclCode ("standard_aes"), context.Devices, null))
			using (Memory inMem = context.CreateBuffer (MemoryFlags.ReadOnly, input.Length))
			using (Memory outMem = context.CreateBuffer (MemoryFlags.WriteOnly, input.Length))
			using (Memory keyMem = context.CreateBuffer (MemoryFlags.ReadOnly, expandedKey.Length))
			using (Memory t0Mem = context.CreateBuffer (MemoryFlags.ReadOnly, AES.T0.Length * 4))
			using (Memory t1Mem = context.CreateBuffer (MemoryFlags.ReadOnly, AES.T1.Length * 4))
			using (Memory t2Mem = context.CreateBuffer (MemoryFlags.ReadOnly, AES.T2.Length * 4))
			using (Memory t3Mem = context.CreateBuffer (MemoryFlags.ReadOnly, AES.T3.Length * 4))
			using (Memory sboxMem = context.CreateBuffer (MemoryFlags.ReadOnly, AES.SBOX.Length * 4)) {
				for (int i = 0; i < expandedKey.Length - 16; i += 4) {
					byte tmp = expandedKey[i];
					expandedKey[i] = expandedKey[i + 3];
					expandedKey[i + 3] = tmp;
					tmp = expandedKey[i + 1];
					expandedKey[i + 1] = expandedKey[i + 2];
					expandedKey[i + 2] = tmp;
				}
				queue.WriteBuffer (keyMem, 0, expandedKey, 0, expandedKey.Length);
				queue.WriteBuffer (t0Mem, 0, AES.T0, 0, AES.T0.Length * 4);
				queue.WriteBuffer (t1Mem, 0, AES.T1, 0, AES.T1.Length * 4);
				queue.WriteBuffer (t2Mem, 0, AES.T2, 0, AES.T2.Length * 4);
				queue.WriteBuffer (t3Mem, 0, AES.T3, 0, AES.T3.Length * 4);
				queue.WriteBuffer (sboxMem, 0, AES.SBOX_UINT32, 0, AES.SBOX_UINT32.Length * 4);
				const int mode = 2;
				int local_loops = 1;
				using (Kernel kernel = prog.CreateKernel ("encrypt" + mode.ToString ())) {
					kernel.SetArgument (0, inMem);
					kernel.SetArgument (1, outMem);
					kernel.SetArgument (2, keyMem);
					kernel.SetArgument (3, t0Mem);
					switch (mode) {
						case 1:
							kernel.SetArgument (4, sboxMem);
							kernel.SetLocalDataShare (5, (int)t0Mem.Size);
							kernel.SetLocalDataShare (6, (int)sboxMem.Size);
							break;
						case 2:
						case 3:
						case 4:
							kernel.SetArgument (4, t1Mem);
							kernel.SetArgument (5, t2Mem);
							kernel.SetArgument (6, t3Mem);
							kernel.SetArgument (7, sboxMem);
							kernel.SetLocalDataShare (8, (int)t0Mem.Size);
							kernel.SetLocalDataShare (9, (int)t0Mem.Size);
							kernel.SetLocalDataShare (10, (int)t0Mem.Size);
							kernel.SetLocalDataShare (11, (int)t0Mem.Size);
							kernel.SetLocalDataShare (12, (int)sboxMem.Size);
							if (mode == 3)
								kernel.SetArgument (13, (uint)(input.Length / 16), 4);
							break;
					}
					if (mode < 3)
						local_loops = 1;

					total += Execute ("write", memTests, input.Length, delegate () {
						queue.WriteBuffer (inMem, 0, input, 0, input.Length);
					});

					int global_size = input.Length / 16 / local_loops;
					int local_size = (int)queue.Device.MaxWorkItemSizes[0];
					if (mode == 4)
						local_size = Math.Min (local_size, ((int)queue.Device.LocalMemSize / 2 - 5120) / 16 * 4 * 2);
					while (local_size > global_size)
						local_size >>= 1;
					if (mode == 4) {
						kernel.SetLocalDataShare (13, local_size / 4 * 16 * 2);
						kernel.SetArgument (14, (uint)(input.Length / 16), 4);
					}

					total += Execute ("kernel(encrypt)", encryptTests, input.Length, delegate () {
						queue.Execute (kernel, 0, global_size, local_size);
					});
				}

				total += Execute ("read", memTests, input.Length, delegate () {
					queue.ReadBuffer (outMem, 0, output, 0, output.Length);
				});
			}
#endif
			WriteTime ("total", total, input.Length);
#if false
			AES.Encrypt (key, input, output_ref);
			for (int i = 0; i < output.Length; i++)
				if (output[i] != output_ref[i]) {
					Console.ForegroundColor = ConsoleColor.Red;
					Console.WriteLine ("err");
					Console.ForegroundColor = ConsoleColor.White;
					break;
				}
#endif

			Console.WriteLine ("cmpl");
			Console.ReadLine ();
		}

		static void CamelliaTest ()
		{
			const int memTests = 1;
			const int encryptTests = 1;
			byte[] key = new byte[16];
			byte[] input = new byte[1024 * 1024 * 64];
			byte[] output = new byte[input.Length];
			byte[] output_ref = new byte[input.Length];
			uint[] keyTable;
			new Random ().NextBytes (key);
			new Random ().NextBytes (input);
			Camellia.GenerateKeyTable (key, out keyTable);

			using (Context context = new Context (DeviceType.GPU))
			using (CommandQueue queue = context.CreateCommandQueue (context.Devices[0], CommandQueueProperties.Default))
			using (CLProgram prog = context.CreateProgram (OclCodeStore.GetOclCode ("camellia"), context.Devices, null))
			using (Memory inMem = context.CreateBuffer (MemoryFlags.ReadOnly, input.Length))
			using (Memory outMem = context.CreateBuffer (MemoryFlags.WriteOnly, input.Length))
			using (Memory keyMem = context.CreateBuffer (MemoryFlags.ReadOnly, keyTable.Length * 4))
			using (Memory sbox1Mem = context.CreateBuffer (MemoryFlags.ReadOnly, Camellia.SBOX1_1110.Length * 4))
			using (Memory sbox2Mem = context.CreateBuffer (MemoryFlags.ReadOnly, Camellia.SBOX2_0222.Length * 4))
			using (Memory sbox3Mem = context.CreateBuffer (MemoryFlags.ReadOnly, Camellia.SBOX3_3033.Length * 4))
			using (Memory sbox4Mem = context.CreateBuffer (MemoryFlags.ReadOnly, Camellia.SBOX4_4404.Length * 4)) {
				TimeSpan total = TimeSpan.Zero;
				queue.WriteBuffer (keyMem, 0, keyTable, 0, keyTable.Length * 4);
				queue.WriteBuffer (sbox1Mem, 0, Camellia.SBOX1_1110, 0, Camellia.SBOX1_1110.Length * 4);
				queue.WriteBuffer (sbox2Mem, 0, Camellia.SBOX2_0222, 0, Camellia.SBOX2_0222.Length * 4);
				queue.WriteBuffer (sbox3Mem, 0, Camellia.SBOX3_3033, 0, Camellia.SBOX3_3033.Length * 4);
				queue.WriteBuffer (sbox4Mem, 0, Camellia.SBOX4_4404, 0, Camellia.SBOX4_4404.Length * 4);
				queue.WriteBuffer (inMem, 0, new byte[inMem.Size], 0, (int)inMem.Size);
				queue.WriteBuffer (outMem, 0, new byte[outMem.Size], 0, (int)outMem.Size);
				const int mode = 1;
				int local_loops = 4;
				if (mode == 2 && local_loops < 4) local_loops = 4;
				using (Kernel kernel = prog.CreateKernel ("encrypt" + mode.ToString ())) {
					kernel.SetArgument (0, inMem);
					kernel.SetArgument (1, outMem);
					kernel.SetArgument (2, keyMem);
					kernel.SetArgument (3, sbox1Mem);
					kernel.SetArgument (4, sbox2Mem);
					kernel.SetArgument (5, sbox3Mem);
					kernel.SetArgument (6, sbox4Mem);
					kernel.SetLocalDataShare (7, (int)sbox1Mem.Size);
					kernel.SetLocalDataShare (8, (int)sbox2Mem.Size);
					kernel.SetLocalDataShare (9, (int)sbox3Mem.Size);
					kernel.SetLocalDataShare (10, (int)sbox4Mem.Size);
					kernel.SetArgument (11, (uint)(input.Length / 16), 4);

					total += Execute ("write", memTests, input.Length, delegate () {
						queue.WriteBuffer (inMem, 0, input, 0, input.Length);
					});

					int global_size = input.Length / 16 / local_loops;
					int local_size = (int)queue.Device.MaxWorkItemSizes[0];
					while (local_size > global_size)
						local_size >>= 1;

					total += Execute ("kernel(encrypt)", encryptTests, input.Length, delegate () {
						queue.Execute (kernel, 0, global_size, local_size);
					});
				}

				total += Execute ("read", memTests, input.Length, delegate () {
					queue.ReadBuffer (outMem, 0, output, 0, output.Length);
				});
				WriteTime ("total", total, input.Length);
			}
#if false
			Camellia.Encrypt (key, input, output_ref);
			for (int i = 0; i < output.Length; i++)
				if (output[i] != output_ref[i]) {
					Console.ForegroundColor = ConsoleColor.Red;
					Console.WriteLine ("err");
					Console.ForegroundColor = ConsoleColor.White;
					break;
				}
#endif

			Console.WriteLine ("cmpl");
			Console.ReadLine ();
		}

		static void AESTest2 ()
		{
			const int memTests = 1;
			const int encryptTests = 1;
			const int ProcessUnitDataSize = 16 * 32; // 32bit-width bitslice
			byte[] key = new byte[16];
			byte[] input = new byte[ProcessUnitDataSize * 2 * 1024 * 64];
			byte[] output = new byte[input.Length];
			byte[] output_ref = new byte[input.Length];
			byte[] expandedKey;
			new Random ().NextBytes (key);
			new Random ().NextBytes (input);
			AES.KeyExpansion (key, out expandedKey);
			TimeSpan total = TimeSpan.Zero;

			bool private_memory_mode = true;

			using (Context context = new Context (DeviceType.GPU))
			using (CommandQueue queue = context.CreateCommandQueue (context.Devices[0], CommandQueueProperties.Default))
			using (CLProgram prog = context.CreateProgram (OclCodeStore.GetOclCode (private_memory_mode ? "bitslice_aes4" : "bitslice_aes3"), context.Devices, null))
			using (Memory mem = context.CreateBuffer (MemoryFlags.ReadWrite, input.Length))
			using (Memory keyMem = context.CreateBuffer (MemoryFlags.ReadWrite, expandedKey.Length * 32)) {
				using (Memory nonsliceKeyMem = context.CreateBuffer (MemoryFlags.WriteOnly, expandedKey.Length))
				using (Kernel kernel = prog.CreateKernel ("bitslice_key")) {
					kernel.SetArgument (0, nonsliceKeyMem);
					kernel.SetArgument (1, keyMem);
					queue.WriteBuffer (nonsliceKeyMem, 0, expandedKey, 0, expandedKey.Length);
					queue.Execute (kernel, 0, expandedKey.Length * 8 / 4, 8);
				}

				int localMemorySize = (int)(queue.Device.LocalMemSize / 2);
				int maxWorkItemSize = (int)queue.Device.MaxWorkItemSizes[0];

				// global/local size setting for encrypt kernel
				int global_size = (private_memory_mode ? input.Length / ProcessUnitDataSize : input.Length / ProcessUnitDataSize * 4);
				int local_size = (private_memory_mode ? int.MaxValue : (localMemorySize / 512) * 4);
				local_size = Math.Min (local_size, maxWorkItemSize);
				local_size = Math.Min (local_size, global_size);

				// global/local size setting for bitslice kernel
				int slice_global_size = input.Length / ProcessUnitDataSize * 32;
				int slice_local_size = (localMemorySize / 512) * 32;
				slice_local_size = Math.Min (slice_local_size, maxWorkItemSize);
				slice_local_size = Math.Min (slice_local_size, slice_global_size);

				total += Execute ("write", memTests, input.Length, delegate () {
					queue.WriteBuffer (mem, 0, input, 0, input.Length);
				});

				using (Kernel kernel_encrypt = prog.CreateKernel ("encrypt"))
				using (Kernel kernel_bitslice = prog.CreateKernel ("bitslice_kernel")) {
					kernel_bitslice.SetArgument (0, mem);
					kernel_bitslice.SetLocalDataShare (1, 512 * slice_local_size / 32);
					kernel_encrypt.SetArgument (0, mem);
					kernel_encrypt.SetArgument (1, keyMem);
					if (!private_memory_mode)
						kernel_encrypt.SetLocalDataShare (2, 512 * local_size / 4);

					total += Execute ("kernel(bitslice)", encryptTests, input.Length, delegate () {
						queue.Execute (kernel_bitslice, 0, slice_global_size, slice_local_size);
					});
					total += Execute ("kernel(encrypt)", encryptTests, input.Length, delegate () {
						queue.Execute (kernel_encrypt, 0, global_size, local_size);
					});
					total += Execute ("kernel(unbitslice)", encryptTests, input.Length, delegate () {
						queue.Execute (kernel_bitslice, 0, slice_global_size, slice_local_size);
					});
				}
				total += Execute ("read", memTests, input.Length, delegate () {
					queue.ReadBuffer (mem, 0, output, 0, output.Length);
				});
			}

			WriteTime ("total", total, input.Length);
#if true
			AES.Encrypt (key, input, output_ref);
			for (int i = 0; i < output.Length; i++)
				if (output[i] != output_ref[i]) {
					Console.ForegroundColor = ConsoleColor.Red;
					Console.WriteLine ("err");
					Console.ForegroundColor = ConsoleColor.White;
					break;
				}
#endif

			Console.WriteLine ("cmpl");
			Console.ReadLine ();
		}

		static void CamelliaTest2 ()
		{
			const int memTests = 1;
			const int encryptTests = 1;
			const int ProcessUnitDataSize = 16 * 32; // 32bit-width bitslice
			byte[] key = new byte[16];
			byte[] input = new byte[ProcessUnitDataSize * 2 * 1024 * 64];
			byte[] output = new byte[input.Length];
			byte[] output_ref = new byte[input.Length];
			uint[] keyTable;
			new Random ().NextBytes (key);
			new Random ().NextBytes (input);
			Camellia.GenerateKeyTable (key, out keyTable);
			TimeSpan total = TimeSpan.Zero;

			using (Context context = new Context (DeviceType.GPU))
			using (CommandQueue queue = context.CreateCommandQueue (context.Devices[0], CommandQueueProperties.Default))
			using (CLProgram prog = context.CreateProgram (OclCodeStore.GetOclCode ("bitslice_camellia"), context.Devices, null))
			using (Memory mem = context.CreateBuffer (MemoryFlags.ReadWrite, input.Length)) {
				/*using (Memory keyMem = context.CreateBuffer (MemoryFlags.ReadWrite, expandedKey.Length * 32))
				using (Memory nonsliceKeyMem = context.CreateBuffer (MemoryFlags.WriteOnly, expandedKey.Length))
				using (Kernel kernel = prog.CreateKernel ("bitslice_key")) {
					kernel.SetArgument (0, nonsliceKeyMem);
					kernel.SetArgument (1, keyMem);
					queue.WriteBuffer (nonsliceKeyMem, 0, expandedKey, 0, expandedKey.Length);
					queue.Execute (kernel, 0, expandedKey.Length * 8 / 4, 8);
				}*/

				int localMemorySize = (int)(queue.Device.LocalMemSize / 2);
				int maxWorkItemSize = (int)queue.Device.MaxWorkItemSizes[0];

				// global/local size setting for encrypt kernel
				int global_size = input.Length / ProcessUnitDataSize;
				int local_size = int.MaxValue;// localMemorySize / 512;
				local_size = Math.Min (local_size, maxWorkItemSize);
				local_size = Math.Min (local_size, global_size);

				// global/local size setting for bitslice kernel
				int slice_global_size = input.Length / ProcessUnitDataSize * 32;
				int slice_local_size = (localMemorySize / 512) * 32;
				slice_local_size = Math.Min (slice_local_size, maxWorkItemSize);
				slice_local_size = Math.Min (slice_local_size, slice_global_size);

				total += Execute ("write", memTests, input.Length, delegate () {
					queue.WriteBuffer (mem, 0, input, 0, input.Length);
				});

				using (Kernel kernel_encrypt = prog.CreateKernel ("encrypt"))
				using (Kernel kernel_bitslice = prog.CreateKernel ("bitslice_kernel"))
				using (Kernel kernel_shuffle1 = prog.CreateKernel ("shuffle_state1"))
				using (Kernel kernel_shuffle2 = prog.CreateKernel ("shuffle_state2")) {
					kernel_bitslice.SetArgument (0, mem);
					kernel_bitslice.SetLocalDataShare (1, 512 * slice_local_size / 32);
					kernel_shuffle1.SetArgument (0, mem);
					kernel_shuffle1.SetLocalDataShare (1, 512 * slice_local_size / 32);
					kernel_shuffle2.SetArgument (0, mem);
					kernel_shuffle2.SetLocalDataShare (1, 512 * slice_local_size / 32);
					kernel_encrypt.SetArgument (0, mem);
					//kernel_encrypt.SetLocalDataShare (1, 512 * local_size);

					total += Execute ("kernel(bitslice)", encryptTests, input.Length, delegate () {
						queue.Execute (kernel_bitslice, 0, slice_global_size, slice_local_size);
					});
					total += Execute ("kernel(shuffle)", encryptTests, input.Length, delegate () {
						queue.Execute (kernel_shuffle1, 0, slice_global_size, slice_local_size);
					});
					total += Execute ("kernel(encrypt)", encryptTests, input.Length, delegate () {
						queue.Execute (kernel_encrypt, 0, global_size, local_size);
					});
					total += Execute ("kernel(shuffle)", encryptTests, input.Length, delegate () {
						queue.Execute (kernel_shuffle2, 0, slice_global_size, slice_local_size);
					});
					total += Execute ("kernel(unbitslice)", encryptTests, input.Length, delegate () {
						queue.Execute (kernel_bitslice, 0, slice_global_size, slice_local_size);
					});
				}
				total += Execute ("read", memTests, input.Length, delegate () {
					queue.ReadBuffer (mem, 0, output, 0, output.Length);
				});
			}

			WriteTime ("total", total, input.Length);
#if true
			Camellia.Encrypt (key, input, output_ref);
			for (int i = 0; i < output.Length; i++)
				if (output[i] != output_ref[i]) {
					ConsoleColor defColor = Console.ForegroundColor;
					Console.ForegroundColor = ConsoleColor.Red;
					Console.WriteLine ("err");
					Console.WriteLine ("  expected | actual | input");
					for (int k = i; k < i + 64 && k < output.Length; k ++) {
						Console.ForegroundColor = (output[k] == output_ref[k] ? defColor : ConsoleColor.Red);
						Console.WriteLine ("    {0}: {1:x2} | {2:x2} | {3:x2}", k, output_ref[k], output[k], input[k]);
					}
					Console.ForegroundColor = defColor;
					break;
				}
#endif

			Console.WriteLine ("cmpl");
			Console.ReadLine ();
		}

		static void ECCTest ()
		{
			const int BigIntBytes = 4 * 8;
			const int PointBytes = BigIntBytes * 3;
			const int InputWorkItemBytes = PointBytes + BigIntBytes;
			const int OutputWorkItemBytes = PointBytes;
			uint[] x1 = new uint[] {0x895aa032, 0x0d07522a, 0x506abf79, 0xabbc5c54, 0x1c2d6914, 0xb758abae, 0x914fa51b, 0xdfa23008};
			uint[] y1 = new uint[] {0xefa18861, 0x602dfbbd, 0xe98d5b8c, 0xf884eb9e, 0x9898b025, 0x022e6bad, 0x31f238ee, 0x0bf40155};
			uint[] z1 = new uint[] {0x00000001, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000};
			uint[] x2 = new uint[] {0xd6d7e35d, 0x2febd950, 0x2f987f4d, 0xb30482f7, 0x1164ce2e, 0xfce2b6ce, 0x12367d71, 0x15c1cdd1};
			uint[] y2 = new uint[] {0xc1add051, 0x2dcfd682, 0x0d53b2d6, 0xbd9ad440, 0xad0f523b, 0x559ebb59, 0x45d34876, 0xdd307c87};
			uint[] z2 = new uint[] {0x00000001, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000};
			uint[] x3 = new uint[] {0xb75c6254, 0x7b278510, 0xf45598f8, 0xdb81bb86, 0x4c48ee2b, 0x1dfe6ba4, 0xcbb54aa0, 0x616966b1};
			uint[] y3 = new uint[] {0x356c3d49, 0x3c98aa53, 0xff99ca5b, 0x3d58a64f, 0xc0ac8b7e, 0x65168611, 0x0bb52f28, 0x9defd775};
			uint[] z3 = new uint[] {0x00000001, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000};
			uint[] s  = new uint[] {0x9b2d206a, 0x8a022706, 0x5ce5a47a, 0x9f363b87, 0xcac90283, 0x2004790d, 0x1f2e5787, 0xadeba125};
			uint[] x = new uint[8], y = new uint[8], z = new uint[8];

			using (Context context = new Context (DeviceType.GPU))
			using (CommandQueue queue = context.CreateCommandQueue (context.Devices[0], CommandQueueProperties.Default))
			using (CLProgram prog = context.CreateProgram (OclCodeStore.GetOclCode ("ecc-p256"), context.Devices, null)) {
				int maxWorkItemSize = (int)queue.Device.MaxWorkItemSizes[0] / 2;
				int parallels = (int)queue.Device.MaxComputeUnits * maxWorkItemSize;
				int local_size = maxWorkItemSize;
				while (local_size > parallels)
					local_size >>= 1;

				using (Memory inMem = context.CreateBuffer (MemoryFlags.ReadOnly, InputWorkItemBytes * parallels))
				using (Memory outMem = context.CreateBuffer (MemoryFlags.WriteOnly, OutputWorkItemBytes * parallels))
				using (Kernel kernel = prog.CreateKernel ("Test")) {
					kernel.SetArgument (0, inMem);
					kernel.SetArgument (1, outMem);

					{
						int wrote = 0;
						for (int i = 0; i < parallels; i ++) {
							queue.WriteBuffer (inMem, wrote, x1, 0, BigIntBytes); wrote += BigIntBytes;
							queue.WriteBuffer (inMem, wrote, y1, 0, BigIntBytes); wrote += BigIntBytes;
							queue.WriteBuffer (inMem, wrote, z1, 0, BigIntBytes); wrote += BigIntBytes;
							queue.WriteBuffer (inMem, wrote, s, 0, BigIntBytes); wrote += BigIntBytes;
							s[0] ++;
						}
					}

					TimeSpan time = Execute (null, 1, 0, delegate () {
						queue.Execute (kernel, 0, parallels, local_size);
					});
					Console.WriteLine ("{0} mul/s", parallels / time.TotalSeconds);

					{
						int read = 0;
						queue.ReadBuffer (outMem, read, x, 0, BigIntBytes); read += BigIntBytes;
						queue.ReadBuffer (outMem, read, y, 0, BigIntBytes); read += BigIntBytes;
						queue.ReadBuffer (outMem, read, z, 0, BigIntBytes);
					}
				}
			}

			/*for (int i = 0; i < 8; i ++)
				Console.WriteLine ("x[{0}]=0x{1:x8}  y[{0}]=0x{2:x8}  z[{0}]=0x{3:x8}", i, x[i], y[i], z[i]);

			Console.WriteLine ("cmpl");
			Console.ReadLine ();*/
		}

		delegate void NoArgDelegate ();

		static TimeSpan Execute (string msg, int loops, int input_length, NoArgDelegate func)
		{
			return Execute (msg, loops, input_length, func, null);
		}

		static TimeSpan Execute (string msg, int loops, int input_length, NoArgDelegate func, NoArgDelegate prepFunc)
		{
			long min = long.MaxValue;
			for (int i = 0; i < loops; i++) {
				if (prepFunc != null)
					prepFunc ();
				Stopwatch sw = Stopwatch.StartNew ();
				func ();
				sw.Stop ();
				min = Math.Min (min, sw.Elapsed.Ticks);
			}
			TimeSpan ret = TimeSpan.FromTicks (min);
			WriteTime (msg, ret, input_length);
			return ret;
		}

		static void WriteTime (string msg, Stopwatch sw, int data_size)
		{
			sw.Stop ();
			WriteTime (msg, sw.Elapsed, data_size);
		}

#if true
		static void WriteTime (string msg, TimeSpan value, int data_size)
		{
			Console.WriteLine ("{0}: {1}ms", msg, value.TotalMilliseconds);
			if (data_size <= 0) return;

			double bytes_per_sec = data_size / value.TotalSeconds;
			Console.WriteLine ("  throughput: {0:f3}Mbps, {1:f3}Gbps, {2:f3}GB/s",
				bytes_per_sec * 8.0 / 1024.0 / 1024.0,
				bytes_per_sec * 8.0 / 1024.0 / 1024.0 / 1024.0,
				bytes_per_sec / 1024.0 / 1024.0 / 1024.0);
		}
#else
		static void WriteTime (string msg, TimeSpan value, int data_size)
		{
			if (msg == "read" || msg == "write" || msg.Contains ("bitslice") || msg.Contains ("shuffle"))
				return;
			//Console.Write ("{0}: {1}ms", msg, value.TotalMilliseconds);
			Console.Write ("{0}: ", msg);
			if (data_size <= 0) return;

			double bytes_per_sec = data_size / value.TotalSeconds;
			//Console.WriteLine ("  throughput: {0:f3}Mbps, {1:f3}Gbps, {2:f3}GB/s",
			Console.WriteLine ("{0:f3}",
				bytes_per_sec * 8.0 / 1024.0 / 1024.0,
				bytes_per_sec * 8.0 / 1024.0 / 1024.0 / 1024.0,
				bytes_per_sec / 1024.0 / 1024.0 / 1024.0);
		}
#endif
	}
}