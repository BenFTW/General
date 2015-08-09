 #!/bin/bash

#Notes and To Do
        #Verify that thresholds are reasonable
        #Create a 1D "blacklist"
        #Add way of determining the next sequence of tapes to add (ie 1A0509L4 is in the library, next set of blank tapes is probably 1A0511L4 through 1A0520L4)
	#Count full 1A and 1C tapes (just for verbose reporting)

#Variables
	#Report and Email settings
	report_file=/tmp/daily_tape_status_report
	email_subject="The Tape Library Hungers..."
	email_address="backupadmsd@woodgrove.com"
	action_needed="false"

        #Maximum number of full 1M or 1D tapes expected
        full_dm_threshold=10
        #Minimum number of empty slots expected
        empty_slots_threshold=10
        #Minimum number of blank 1D tapes expected
        blank_d_threshold=1
        #Minimum number of recyclable 1D tapes expected
        recyclable_d_threshold=50
        #Minimum number of blank 1M tapes expected
        blank_m_threshold=20
        #Minimum number of blank 1A tapes expected
        blank_a_threshold=20
        #Minimum number of blank 1C tapes expected
        blank_c_threshold=40

        #Establish base values for how many tapes are to be added to the library
	empty_slots=0
        recyclable_d=0
	needed_d=0
	needed_dr=0
        needed_m=0
        needed_a=0
        needed_c=0
	available_d=0
	full_dm=0
	full_a=0
	full_c=0
	blank_d=0
	blank_m=0
	blank_a=0
	blank_c=0
        needed_total=0
	remove_dm=0
	temp_var=0

	#Script Parameters
	report_type=basic
	no_email=false
	silent_mode=false
	until [ -z "$1" ]
	do
		case "$1" in
			"verbose")
				report_type=verbose
				;;
			"nomail")
				no_email=true
				;;
			"silent")
				silent_mode=true
				;;
			*)
				echo Invalid argument: $1
				echo
				echo Available options:
				echo '  'verbose - Outputs additional data to the report file
				echo '  'nomail'  '- Does not e-mail the generated report file
				echo '  'silent'  '- Does not print the report file
				echo
				exit 1
				;;
		esac
		shift
	done

#Handle full 1M and 1D tapes
	full_dm=`mminfo -avq 'type=LTO Ultrium-5,full,location=TAPE_LIB,!volrecycle' -r volume,pool |egrep -c '^1D|^1M'`
        if [ $full_dm -ge $full_dm_threshold ]; then
		remove_dm=`expr $full_dm - $full_dm % 10`
        fi		

#Handle recyclable 1D tapes in the library
        recyclable_d=`mminfo -avq 'type=LTO Ultrium-5,full,location=TAPE_LIB,volrecycle' | egrep -c '^1D'`
        if [ $recyclable_d -lt $recyclable_d_threshold ]; then
                #Calculate the number of tapes needed to reach the threshold
                temp_var=`expr $recyclable_d_threshold - $recyclable_d + 10`
                needed_dr=`expr $temp_var - $temp_var % 10`
                available_d=`mminfo -avq 'type=LTO Ultrium-5,volrecycle' -r volume,pool |egrep '^1D'|grep -vi norecycle | head -$needed_dr | grep -c D`
        fi
		
#Handle blank 1M tapes
        blank_m=`nsrjb -j TAPE_LIB | grep ': -' | grep -c 1M`
        if [ $blank_m -le $blank_m_threshold ]; then
                temp_var=`expr $blank_m_threshold - $blank_m + 10`
                needed_m=`expr $temp_var - $temp_var % 10`
        fi

#Handle blank 1D tapes
        blank_d=`nsrjb -j TAPE_LIB | grep ': -' | grep -c 1D`

#Handle blank 1C tapes
        blank_c=`nsrjb -j TAPE_LIB | grep ': -' | grep -c 1C`
        if [ $blank_c -lt $blank_c_threshold ]; then
                temp_var=`expr $blank_c_threshold - $blank_c + 10`
                needed_c=`expr $temp_var - $temp_var % 10`
        fi

#Handle blank 1A tapes
        blank_a=`nsrjb -j TAPE_LIB | grep ': -' | grep -c 1A`
        if [ $blank_a -lt $blank_a_threshold ]; then
                temp_var=`expr $blank_a_threshold - $blank_a + 10`
                needed_a=`expr $temp_var - $temp_var % 10`
        fi
#Count Empty Slots
        empty_slots=`nsrjb -j TAPE_LIB | grep -c ':     '`

#Count needed tapes
        needed_total=`expr $needed_a + $needed_m + $needed_c + $needed_d + $needed_dr`

#Report
	echo ======== Tape Status Report ======== > $report_file
	echo '     'Script Name: $0 >> $report_file
	echo Report Generated: `date +%F', '%R` >> $report_file
	echo ----- - - - - - -'  '- - - - - - ----- >> $report_file
	echo Action Items: >> $report_file
	echo >> $report_file
	if [ $remove_dm -ne 0 ]; then
	action_needed="true"
	echo Remove $remove_dm full 1D/1M tapes. >> $report_file
	fi
	if [ $needed_a -ne 0 ]; then
	action_needed="true"
	echo '   'Add $needed_a blank 1A tapes. >> $report_file
	fi
	if [ $needed_c -ne 0 ]; then
	action_needed="true"
	echo '   'Add $needed_c blank 1C tapes. >> $report_file
	fi
	if [ $needed_m -ne 0 ]; then
	action_needed="true"
	echo '   'Add $needed_m blank 1M tapes. >> $report_file
	fi
	if [ $needed_d -ne 0 ]; then
	action_needed="true"
	echo '   'Add $needed_d blank 1D tapes. >> $report_file
	fi
	if [ $needed_dr -ne 0 ]; then
	action_needed="true"
	echo '   'Add $needed_dr recycled 1D tapes. >> $report_file
	fi
	echo >> $report_file
	echo ----- - - - - - -'  '- - - - - - ----- >> $report_file
	echo '   'Warnings: >> $report_file
	echo >> $report_file
	if [ $available_d -lt $needed_dr ]; then
		echo Needed Recyclable 1D Tapes...: $needed_dr >> $report_file
		echo Available Recyclable 1D Tapes: $available_d >> $report_file
	fi
	if [ $needed_total -ge $empty_slots ]; then
		echo Tapes to Load: $needed_total >> $report_file
		echo Empty Slots..: $empty_slots >> $report_file
	fi
	echo >> $report_file
	#Verbose Reporting
	if [ "$report_type" == "verbose" ]; then
		echo ----- - - - - - -'  '- - - - - - ----- >> $report_file
		echo Detailed Report: >> $report_file
		echo >> $report_file
		echo -e "Empty or Unlabeled Tapes in Jukebox" >> $report_file
		echo -e "     Tape Type:\t1A\t1C\t1M\t1D\tEmpty Slots" >> $report_file
		echo -e "        Loaded:\t$blank_a\t$blank_c\t$blank_m\t$blank_d\t$empty_slots" >> $report_file
		echo -e "     Threshold:\t$blank_a_threshold\t$blank_c_threshold\t$blank_m_threshold\t$blank_d_threshold\t$empty_slots_threshold" >> $report_file
		echo >> $report_file
		echo -e "Full Tapes in Jukebox" >> $report_file
		echo -e "     Tape Type:\t1A\t1C\t1M+1D" >> $report_file
                echo -e "        Loaded:\t$full_a\t$full_c\t$full_dm" >> $report_file
                echo -e "     Threshold:\tN/A\tN/A\t$full_dm_threshold" >> $report_file
                echo >> $report_file
                echo -e "Recyclable 1D Tapes" >> $report_file
                echo -e "    In Jukebox: $recyclable_d" >> $report_file
                echo -e "     Threshold: $recyclable_d_threshold" >> $report_file
                echo -e "Not in Jukebox: $available_d" >> $report_file
                echo >> $report_file
	fi
		
	echo ========== End of Report =========== >> $report_file

if [ "$silent_mode" == "false" ]; then
	cat $report_file
fi

if [ "$no_email" == "false" ]; then
	if [ "$action_needed" == "true" ]; then
		/bin/mail -s "$email_subject" "$email_address" < $report_file
	fi
fi

