using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace IpAddresses
{
    public class Class1
    {
        public static string ClrFunction(string inputString)
        {
            try {
                String[] split = inputString.Split('.');
                int firstOctet = Convert.ToInt32(split[0]);
                if (firstOctet < 1 || firstOctet > 255) {
                    return ("Invalid range");
                }
                if (firstOctet >= 1 && firstOctet <= 127) {
                    return ("Class A " + "Mask: 255.0.0.0");
                }
                else
                    if (firstOctet >= 128 && firstOctet <= 191)
                {
                    return ("Class B " + "Mask: 255.255.0.0");
                }
                else
                        if (firstOctet >= 192 && firstOctet <= 223)
                {
                    return ("Class C " + "Mask: 255.255.255.0");
                }
                else
                            if (firstOctet >= 224 && firstOctet <= 239)
                {
                    return ("Class D " + "Mask: 255.255.255.255");
                }
                else
                                if (firstOctet >= 240 && firstOctet <= 255)
                {
                    return ("Class E " + "Mask: 255.255.255.255");
                }
                //return (split[0]);
            } catch (Exception e)
            {
                return ("Input String cannot be parsed to Integer");
            }
            return "";
        }
    }
}
