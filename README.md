IMPORTANT UPDATE (2012-12-30)
=============================
Just 24h after, the bug seems to be already adressed by whatsapp, so this exploit wont break the legitimate link between a phone and the whatsapp account anymore. The exploit will continue forcing the send of validation codes and annoying the victim through sms and phone calls, though.

whatsploit
==========
by alist3r

based on yowsup whatsapp python api by Tarek Galal

exploit for temporary disabling whatsapp access to an arbitrary list of phone numbers using the "request code" feature to temporary invalidate whatsapp legitimate access to the actual phone number owner.

this is a proof of concept, demonstrating that launching a massive DoS attack against a big amount of whatsapp users is indeed possible. with a speed of 6,25 attacks per sec reached in our benchmarks, only 20 people with a distributed attack could deactivate the 10 million spanish users base in less than 24h.

the victim(s) receive a cofirmation code via sms or automated phone call (see the code to configure used method).
due to a flaw in the logic flow of whatsapp, the previous linked account and internal password get invalidated even before the new code resquest has been fulfilled, giving the victim no chance to protect his original link against a non legitimate validation code request. 

this is a very basic flaw that whatsapp could solve with no effort, and we hope they do asap.

usage:
./whatsploit.sh file-with-a-list-of-numbers

ensure that you do one of the both:

  * the list of numbers contains the country code prepended to the number, i.e. 34600000000 for the spanish number 600000000. Dont use "00" or "+", just prepend the country code.
  * open the script in order to set the variable "countrycode" to your country's phone code. then you will not need to add the country code to all the numbers in the number list file nor the manual inputs in interactive mode.

interactive usage:
./whatsploit.sh (without parameters)

will take the input from the keyboard and each time you press enter, the script will try to process the given number
(caution, there's no input validation implemented, dont type weird things there) 

other tools included
====================

whatsappquery.sh

whatsapp account assessment script

quite the same usage as whatsploit.sh, but this script just assesses the existence of a whatsapp account linked to the given numbers. The script reports results on screen and automatically adds found numbers to the log file "whatsappusers.list", which can be used as an input file for whatsaploit.

whatsappquery.sh can be feeded with a list of phone numbers of a given country/state/province in order to exactly know how many whatsapp users exists in the given zone, as well as their phone numbers. researchers have sucessfully tested this concept in Spain and have found 9.832.654 whatsapp users at that time (fabruary 2012)


yowsup

This repo includes a full working copy of the yowsup api by Tarek Galal, with all the original documentation, files, examples, readme, and the yowsup-cli utility, wich whatsploit.sh relies on

DISCLAIMER
==========
This information is for research and academic purposes only. This info is not to be abused and is only published as a proof of concept. I am not responsible for any damage that you may create using this contents and software in an inappropiate way. Experiment onlye with your own phone numbers.
