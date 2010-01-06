using System;
using System.IO;
using System.Collections.Generic;
using System.Reflection;

namespace oclCrypto
{
	static class OclCodeStore
	{
		static Assembly _asm;
		static Dictionary<string, string> _cache;
		static string _prefix;

		static OclCodeStore ()
		{
			_asm = Assembly.GetExecutingAssembly ();
			_cache = new Dictionary<string, string> ();
			_prefix = typeof (OclCodeStore).Namespace + ".";
		}

		public static string[] GetOclCodeList ()
		{
			return _asm.GetManifestResourceNames ();
		}

		public static string GetOclCode (string name)
		{
			name = _prefix + name + ".cl";
			using (Stream strm = _asm.GetManifestResourceStream (name))
			using (StreamReader reader = new StreamReader (strm)) {
				return reader.ReadToEnd ();
			}
		}
	}
}
