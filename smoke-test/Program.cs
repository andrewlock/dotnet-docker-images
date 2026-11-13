using System;
using System.Globalization;
using System.IO;
using System.IO.Compression;
using System.Net.Http;
using System.Runtime.InteropServices;
using System.Security.Cryptography;
using System.Text;

// Exercises the native dependencies that `dotnet --info` never loads.
static class Program
{
    static int failures;

    static int Main()
    {
        Console.WriteLine($"{RuntimeInformation.FrameworkDescription} on {RuntimeInformation.OSDescription}");

        Check("ICU", () =>
        {
            // In invariant mode (no ICU) Turkish casing rules aren't applied
            var tr = new CultureInfo("tr-TR");
            if ("i".ToUpper(tr) != "İ") throw new Exception("culture data unavailable (invariant mode?)");
        });

        Check("OpenSSL (libcrypto)", () =>
        {
            using (var sha = SHA256.Create()) sha.ComputeHash(Encoding.UTF8.GetBytes("hello"));
            using (var rsa = RSA.Create())
            {
                rsa.KeySize = 2048;
                var data = Encoding.UTF8.GetBytes("hello");
                var sig = rsa.SignData(data, HashAlgorithmName.SHA256, RSASignaturePadding.Pkcs1);
                if (!rsa.VerifyData(data, sig, HashAlgorithmName.SHA256, RSASignaturePadding.Pkcs1)) throw new Exception("verify failed");
            }
        });

        Check("OpenSSL (libssl) + CA certs", () =>
        {
            using (var client = new HttpClient())
                client.GetAsync("https://www.microsoft.com").GetAwaiter().GetResult().Dispose();
        });

        Check("zlib", () =>
        {
            var input = Encoding.UTF8.GetBytes(new string('a', 10000));
            var ms = new MemoryStream();
            using (var gz = new GZipStream(ms, CompressionMode.Compress, leaveOpen: true)) gz.Write(input, 0, input.Length);
            ms.Position = 0;
            var output = new MemoryStream();
            using (var gz = new GZipStream(ms, CompressionMode.Decompress)) gz.CopyTo(output);
            if (output.Length != input.Length) throw new Exception("round-trip mismatch");
        });

        return failures == 0 ? 0 : 1;
    }

    static void Check(string name, Action test)
    {
        try { test(); Console.WriteLine($"  [PASS] {name}"); }
        catch (Exception ex) { failures++; Console.WriteLine($"  [FAIL] {name}: {ex.GetType().Name}: {ex.Message}"); }
    }
}
