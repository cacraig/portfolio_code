#!/usr/bin/perl

################################################################################################### 
# GENERAL DESCRIPTION
# 
# A command-line interface to quality control.
#
# INPUT
#
# Most of the commands accept a list of stations, parameters, start times, and end times. The list of
# stations must follow the first argument, the list of parameters must follow '-parameters', and the
# start times and end times must follow '-dates'. The word 'ALL' can be substituted for the list of
# station or the list of parameters. Additionally, the name of a network may substitute the list of
# stations. Most dates are formatted as 'YYYYMMDDHHMMSS'. Any arguments after these are command 
# specific. Refer to the command's description for further details. The following are some examples:
#
# perl QC.pl -range CAST CLAY CLIN -parameters temp rh st -dates 20070320120000 20070321150000
# perl QC.pl -buddy CAST CLAY CLIN -parameters temp rh st -dates 20070320120000 20070321150000 200
# perl QC.pl -buddy ALL -parameters temp rh st -dates 20070320120000 20070321150000
# perl QC.pl -removeFlags KRDU KGSO CLIN -parameters ALL -dates 20070320120000 20070321150000
# perl QC.pl -buddy ALL -parameters ALL -dates 20070320120000 20070321150000
# perl QC.pl -statistics CAST CLAY CLIN -parameters temp rh st -dates 032012 032115 3 1 (note difference in date format)
#
#
#
# USE OF COMMANDS
#
# -realtime
#
# 	Executes the version of quality control which runs in real time
#
# -range [stations...] -parameters [parameters...] -dates [start time] [end time] {flag}
#
#	Executes range check for the selected stations, parameters, and time frame. If 'flag' is
#	the last argument, flags will be inserted into the database. Otherwise, no changes
#	will be made in the database.
#
# -buddy [stations...] -parameters [parameters...] -dates [start time] [end time] [distance]
#
#	Exectues buddy check for the selected stations, parameters, and time frame. The argument
#	'distance' is the size of the radius of influence in kilometers.
#
# -statistics [stations...] -parameters [parameters...] -dates [start time] [end time] [day range] [hour range]
#
# 	Compile statistical data needed for range check for the selected stations, parameters, and time frame.
#	Note that data if formatted as 'MMDDHH' as an other date specifications would be irrelevant (e.g. year
#	is not needed). The arguments 'day range' and 'hour range' are the time period over which the moving 
#	averages are calculated. Refer to the module which calculates these statistics for a full explanation 
#	of 'day range' and 'hour range'.
#	
# -getRangeStats [station] [parameter] [start time] [end time]
#
#	Get the statistics calculated for range check for a SINGLE station, SINGLE parameter, and a given time frame.
#
# -insertFlags [stations...] -parameters [parameters...] -dates [start time] [end time] [new flag]
#
#	Insert QC flags for the selected stations, parameters, and time frame. The argument 'new flag' is the flag
#	to be inserted. Note that this feature will do whatever it is told to do, even if that means writing flags
#	for parameters a station does not report. Use with caution.
#
# -removeFlags [stations...] -parameters [parameters...] -dates [start time] [end time] [old flag]
#
#	Remove flags from the selected stations, parameters, and time frame. The argument 'old flag' is the flag
#	to be removed.
#
# -replaceFlags [stations...] -parameters [parameters...] -dates [start time] [end time] [old flag] [new flag]
#
#	Replace flags for the selected stations, parameters, and time frame. The argument 'old flag' is the flag
#	to be replaced and 'new flag' the flag which replaces the old flag.
#
#
# -viewQCFlags
#
#	
#
# -viewQCCheck [stations...] -parameters [parameters...] -dates [start time] [end time] [level_low] {level_high}
#
#	View all of the observations whose overall quality control score is greater than a given level. If only
#	one level is specified, observations whose failure level is at or above this level will be displayed. If 
#	two are given, observations who failure level is between the two specified levels will be displayed.
#
# -nullFlags [stations...] -parameters [parameters...] -dates [start time] [end time]
#
#	Remove flags whose respective parameter is NULL.
#
# -rangeRepair
#
# -dailyEmail
#
#
#
################################################################################################### 

use DataExtractor;
use Utilities;
use Mysql;
use strict;

my $database_name = "xxxx";
my $user = "xxxx";
my $password = "xxxx";
my $machine = "capefear.meas.ncsu.edu";



my $db = Mysql->Connect($machine,$database_name,$user,$password) or die "\nCould not connect to database '".$database_name."' as user '".$user."' at line ".__LINE__." in 'QC.pl'\n\n";

run();

################################################################################################### 
# Examines the first argument on the command-line to determine which action to take.
################################################################################################### 
sub run(){
	
	my $command = $ARGV[0];
	
	if($command eq "-realtime"){ execute_real_time();}
	elsif($command eq "-range"){ execute_range_check();}
	elsif($command eq "-buddy"){ execute_buddy_check();}
	elsif($command eq "-statistics"){ compute_statistics();}
	elsif($command eq "-getRangeStats"){ get_range_stats();}
	elsif($command eq "-insertFlags"){ insert_flags();}
	elsif($command eq "-removeFlags"){ remove_flags();}
	elsif($command eq "-replaceFlags"){ replace_flags();}
	elsif($command eq "-viewQCFlags"){ view_qc_flags();}
	elsif($command eq "-rangeRepair"){ repair_range();}
	elsif($command eq "-dailyEmail"){ daily_email();}
	elsif($command eq "-passAll"){ pass_all_stations();}
	elsif($command eq "-nullFlags"){ nullify_flags();}
	elsif($command eq "-viewQCCheck"){ view_qc_check();}
	elsif($command eq "-rain"){ execute_rain_qc();}
	elsif($command eq "-trend"){ execute_trend();}
	else { print "\ncommand ".$ARGV[0]." is not recognized\n\n";}
}

################################################################################################### 
# Execute the real time quality control.
################################################################################################### 
sub execute_real_time(){
	
	use QC_Real_Time;
	
	QC_Real_Time::run(\$db);
}

################################################################################################### 
# Inserts the given flag to the database. Note that this feature will do exactly what it is told to 
# do, even if a given parameter has no data for the particular station selected.
################################################################################################### 
sub insert_flags(){
	
	if($ARGV[1] eq ""){ print "\nusage: -insertFlags [stations...] -parameters [parameters...] -dates [start time] [end time] [new flag]\n\n";return;}
	
	my @input = parse_input();
	
	my $new_flag = $ARGV[$input[4]];
	
	Flag::insert_flags(\$db,$input[0],$input[1]->[0],$input[2]->[0],$input[3]->[0],$new_flag);
}

################################################################################################### 
# Removes a given flag from the database.
################################################################################################### 
sub remove_flags(){
	
	if($ARGV[1] eq ""){ print "\nusage: -removeFlags [stations...] -parameters [parameters...] -dates [start time] [end time] [old flag]\n\n";return;}
	
	my @input = parse_input();
	
	my $old_flag = $ARGV[$input[4]];
	
	Flag::remove_flags(\$db,$input[0],$input[1]->[0],$input[2]->[0],$input[3]->[0],$old_flag);
}

################################################################################################### 
# Replaces one flag with another in the database.
################################################################################################### 
sub replace_flags(){
	
	if($ARGV[1] eq ""){ print "\nusage: -replaceFlags [stations...] -parameters [parameters...] -dates [start time] [end time] [old flag] [new flag]\n\n";return;}
	
	my @input = parse_input();
	
	my $old_flag = $ARGV[$input[4]];
	my $new_flag = $ARGV[$input[4]+1];
	
	Flag::replace_flags(\$db,$input[0],$input[1]->[0],$input[2]->[0],$input[3]->[0],$old_flag,$new_flag);
}

################################################################################################### 
# For a given flag on the command-line, inserts the flag concatented with '0' (e.g. 'R0') into the \
# database for the selected stations, parameters, and time period.
################################################################################################### 
sub pass_all_stations(){
	
	if($ARGV[1] eq ""){ print "\nusage: -passAll [stations...] -parameters [parameters...] -dates [start time] [end time] [flag]\n\n";return;}
	
	my @input = parse_input();
	
	Flag::update_flags(\$db,$input[0],$input[1]->[0],$input[2],$input[3],$ARGV[$input[4]]);
}

################################################################################################### 
# Executes range check for the selected stations, parameters, and time period.
################################################################################################### 
sub execute_range_check(){
	
	if($ARGV[1] eq ""){ print "\nusage: -range [stations...] -parameters [parameters...] -dates [start time] [end time]\n\n";return;}
	
	my @input = parse_input();
	
	#-------------------------------------------------------
	# Give input data better names.
	#-------------------------------------------------------
	my @stations = @{$input[0]};
	my @parameters = @{$input[1]};
	my @start_times = @{$input[2]};
	my @end_times = @{$input[3]};
	my $last_element = $input[4];		# index to the last element given on command-line
	
	my @parameters_used;
	
	# if the option to break up quality control has not been selected
	if($ARGV[$last_element] ne "-break"){
		
		if($ARGV[$last_element] eq "flag2"){ @parameters_used = Utilities::isolate_needed_parameters($parameters[0],$parameters[1],0);}
		
		my @data = QC_Range::data_setup(\$db,\@stations,\@parameters,\@start_times,\@end_times);
		
		my @failed;
		
		if($data[0] != -1){ 
		
			@failed = QC_Range::run($data[0],$data[2],$data[1]);
	
			#------------------------------------
			# 	PRINT FAILED OBSERVATIONS
			#------------------------------------
			if(@{$failed[1]}==0){ print "Everything has passed quality control!\n\n";}
			else {
				print "The following ".@{$failed[1]}." observations have failed quality control:\n\n";
				QC_Range::print_data($failed[1],"R",0);
			}
		
			#------------------------------------
			# 	FLAG DATABASE
			#------------------------------------
			if($ARGV[$last_element] eq "flag"){
	
				Flag::write_to_database(\$db,$failed[1],"R");
				Flag::write_to_database(\$db,$failed[0],"R");
			}
			
			if($ARGV[$last_element] eq "flag2"){
				
				Flag::update_flags(\$db,\@stations,\@parameters_used,\@start_times,\@end_times,"R");
				Flag::write_to_database(\$db,$failed[1],"R");
			}
		}
	} else {
	
		my $station_breaks = int $ARGV[$last_element+1];	# break up every X stations
		my $parameter_breaks = int $ARGV[$last_element+2];	# break up every X parameters
		my $hour_breaks = int $ARGV[$last_element+3];		# break up every X hours
		
		my @stations_broken;				# new array to hold a station subarray
		my @parameters_broken;				# new array to hold a parameter subarray
		my @hours_broken;				# new array to hold a time subarray
		my @start_times_broken;
		my @end_times_broken;
		
		my $last_station;				# index of last station in current station sub-array
		my $last_parameter;				# index of last parameter in current parameter sub-array
		my $last_hour;
		
		if($hour_breaks!=0){ @hours_broken = Utilities::list_hours($start_times[0],$end_times[0])};
		
		if($station_breaks == -1){ $station_breaks = @stations;}
		if($parameter_breaks == -1){ $parameter_breaks = @{$parameters[0]};}
		if($hour_breaks == -1){ $hour_breaks = @hours_broken;}
		
		#-------------------------------------------------------
		# Loop through all of the stations.
		#-------------------------------------------------------
		for(my$i=0;$i<@stations;$i+=$station_breaks){
			
			# determine index of last station in current sub-array
			if($i+$station_breaks < @stations){ $last_station = $i+$station_breaks-1;} else { $last_station = @stations-1;}
			
			# create station sub-array
			@stations_broken = @stations[$i...$last_station];
			print "---------------------------------------------------\n";
			print "Running range check for station ".$i." [".$stations[$i]."] to station ".$last_station." [".$stations[$last_station]."] of ".@stations." total stations\n";
			
			#-------------------------------------------------------
			# Loop through all of the parameters
			#-------------------------------------------------------
			for(my$j=0;$j<@{$parameters[0]};$j+=$parameter_breaks){
				
				# determine index of last station in current sub-array
				if($j+$parameter_breaks < @{$parameters[0]}){ $last_parameter = $j+$parameter_breaks-1;} else { $last_parameter = @{$parameters[0]}-1;}
				
				# create parameter sub-array
				for(my$k=0;$k<@parameters;$k++){ my @temp = @{$parameters[$k]};my @newArray = @temp[$j...$last_parameter];$parameters_broken[$k] = \@newArray;}
				
				print "---------------------------------------------------\n";
				print "Running range check for parameter ".$j." [".$parameters[0]->[$j]."] to parameter ".$last_parameter." [".$parameters[0]->[$last_parameter]."] of ".@{$parameters[0]}." total parameters\n";
				
				my $not_last_element = 1;
				my $last_time;
				
				#-------------------------------------------------------
				# Loop through all of the hours.
				#-------------------------------------------------------
				for(my$k=0;$k<@hours_broken-1;$k+=$hour_breaks){
					
					# determine index of last station in current sub-array
					if($k+$hour_breaks < @hours_broken){ $last_hour = $k+$hour_breaks;} else { $not_last_element = 0; $last_hour = @hours_broken-1;}
					
					# set the end time minute equal to "29" if the observation time is not the final end time
					if($not_last_element){ $last_time = substr($hours_broken[$last_hour],0,10)."2900";} else{ $last_time = $hours_broken[$last_hour]};
					
					# set an array of start times and an array of end times equal to the appropriate values
					# each array element sets the time period for a single station
					for(my$l=0;$l<@start_times;$l++){ $start_times_broken[$l] = $hours_broken[$k]; $end_times_broken[$l] = $last_time;}
					
					
					print "---------------------------------------------------\n";
					print "Running range check for hour ".$k." [".$hours_broken[$k]."] to hour ".$last_hour." [".$last_time."] of ".@hours_broken." total hours\n";
					
					my @data = QC_Range::data_setup(\$db,\@stations_broken,\@parameters_broken,\@start_times_broken,\@end_times_broken);
					
					if($data[0]==-1){ next;}
					
					my @obs = QC_Range::run($data[0],$data[2],$data[1]);
					
					#------------------------------------
					# 	PRINT FAILED OBSERVATIONS
					#------------------------------------
					if(@{$obs[1]}==0){ print "\nEverything has passed quality control!\n\n";}
					else {
						print "\nThe following ".@{$obs[1]}." observations have failed quality control:\n\n";
						QC_Range::print_data($obs[1],"R",0);
					}
					
					# flag data if option selected
					if($ARGV[$last_element+4] eq "flag"){
	
						Flag::write_to_database(\$db,$obs[1],"R");
						Flag::write_to_database(\$db,$obs[0],"R");
					}
					
					if($ARGV[$last_element+4] eq "flag2"){
						
						Flag::update_flags(\$db,\@stations_broken,$parameters_broken[0],\@start_times_broken,\@end_times_broken,"R");
						Flag::write_to_database(\$db,$obs[1],"R");
					}
					
					print "\n";	
				}
			}
		}
	}
}

################################################################################################### 
# Executes buddy check for the selected stations, parameters, and time period.
################################################################################################### 
sub execute_buddy_check(){
	
	if($ARGV[1] eq ""){ print "\nusage: -buddy [stations...] -parameters [parameters...] -dates [start time] [end time] [distance]\n\n";return;}
	
	use QC_Buddy;
	
	my @input = parse_input();
	
	#-------------------------------------------------------
	# Give input data better names.
	#-------------------------------------------------------
	my @stations = @{$input[0]};
	my @parameters = @{$input[1]};
	my @start_times = @{$input[2]};
	my @end_times = @{$input[3]};
	my $last_element = $input[4];		# index to the last element given on command-line
	
	if($ARGV[$last_element]==undef){ print "\nPlease select radius of influence!\n\n"; return;}
	
	#-------------------------------------------------------
	# If buddy check tasks were not forced to be broken up.
	#-------------------------------------------------------
	if($ARGV[$last_element+1] ne "-break"){
		
		my $start = (times)[0];
		
		# set up the data and datastructures needed to perform buddy check
		my @data = QC_Buddy::data_setup(\$db,\@stations,\@parameters,\@start_times,\@end_times,$ARGV[$last_element]);
		
		if($data[0]==0){ print "\nNo observations for given time period\n\n";exit;}
		
		my $end = (times)[0];
		printf "Elapsed time: %.2f seconds.\n\n",$end - $start;
		my $start = (times)[0];
		
		print "Quality Control Underway...\n\n";
		
		# perform buddy check
		my @obs = QC_Buddy::run($data[0],$data[1],$data[2],$data[3]);
		
		$end = (times)[0];
		printf "Elapsed time: %.2f seconds.\n\n",$end - $start;
		
		my @failed = @{$obs[1]};	# array of observations which have failed buddy check
	
		Buddy_util::print_data(\@failed,"B",0);
		
		my $num_failed = @failed;
		
		print "\n$num_failed observations have failed buddy check\n\n";
		
		if($ARGV[$last_element+1] eq "flag"){
	
			Flag::write_to_database(\$db,\@failed,"B");
			Flag::write_to_database(\$db,$obs[0],"B");
		}
		
		if($ARGV[$last_element+1] eq "flag2"){
			
			my @parameters_used = Utilities::isolate_needed_parameters($parameters[0],$parameters[4],0);
			my %missed_obs = Buddy_util::hash_missed_obs($obs[2]);
			
			Flag::update_flags2(\$db,\@stations,\@parameters_used,\@start_times,\@end_times,"B",\%missed_obs);
			Flag::write_to_database(\$db,\@failed,"B");
		}
			
		
	#-------------------------------------------------------
	# Otherwise, buddy check tasks should be broken up.
	#-------------------------------------------------------
	} else {
	
		my $station_breaks = int $ARGV[$last_element+2];	# break up every X stations
		my $parameter_breaks = int $ARGV[$last_element+3];	# break up every X parameters
		my $hour_breaks = int $ARGV[$last_element+4];		# break up every X hours
		
		my @stations_broken;				# new array to hold a station subarray
		my @parameters_broken;				# new array to hold a parameter subarray
		my @hours_broken;				# new array to hold a time subarray
		my @start_times_broken;
		my @end_times_broken;
		
		my $last_station;				# index of last station in current station sub-array
		my $last_parameter;				# index of last parameter in current parameter sub-array
		my $last_hour;
		
		@parameters = Utilities::isolate_needed_parameters($parameters[0],$parameters[4],1);

		if($hour_breaks!=0){ @hours_broken = Utilities::list_hours($start_times[0],$end_times[0])};
		
		if($station_breaks == -1){ $station_breaks = @stations;}
		if($parameter_breaks == -1){ $parameter_breaks = @parameters;}
		if($hour_breaks == -1){ $hour_breaks = @hours_broken;}
		
		#-------------------------------------------------------
		# Loop through all of the stations.
		#-------------------------------------------------------
		for(my$i=0;$i<@stations;$i+=$station_breaks){
			
			# determine index of last station in current sub-array
			if($i+$station_breaks < @stations){ $last_station = $i+$station_breaks-1;} else { $last_station = @stations-1;}
			
			# create station sub-array
			@stations_broken = @stations[$i...$last_station];
			print "---------------------------------------------------\n";
			print "Running buddy check for station ".$i." [".$stations[$i]."] to station ".$last_station." [".$stations[$last_station]."] of ".@stations." total stations\n";
			
			#-------------------------------------------------------
			# Loop through all of the parameters
			#-------------------------------------------------------
			for(my$j=0;$j<@parameters;$j+=$parameter_breaks){
				
				# determine index of last station in current sub-array
				if($j+$parameter_breaks < @parameters){ $last_parameter = $j+$parameter_breaks-1;} else { $last_parameter = @parameters-1;}
				
				@parameters_broken = @parameters[$j...$last_parameter];
				
				print "---------------------------------------------------\n";
				print "Running buddy check for parameter ".$j." [".$parameters[$j]."] to parameter ".$last_parameter." [".$parameters[$last_parameter]."] of ".@parameters." total parameters\n";
				
				my $not_last_element = 1;
				my $last_time;
				
				#-------------------------------------------------------
				# Loop through all of the hours.
				#-------------------------------------------------------
				for(my$k=0;$k<@hours_broken-1;$k+=$hour_breaks){
					
					# determine index of last station in current sub-array
					if($k+$hour_breaks < @hours_broken && $hour_breaks != -1){ $last_hour = $k+$hour_breaks;} else { $not_last_element = 0; $last_hour = @hours_broken-1;}
					
					# set the end time minute equal to "29" if the observation time is not the final end time
					if($not_last_element){ $last_time = substr($hours_broken[$last_hour],0,10)."2900";} else{ $last_time = $hours_broken[$last_hour]};
					
					# set an array of start times and an array of end times equal to the appropriate values
					# each array element sets the time period for a single station
					for(my$l=0;$l<@start_times;$l++){ $start_times_broken[$l] = $hours_broken[$k]; $end_times_broken[$l] = $last_time;}
					
					print "---------------------------------------------------\n";
					print "Running buddy check for hour ".$k." [".$hours_broken[$k]."] to hour ".$last_hour." [".$last_time."] of ".@hours_broken." total hours\n";
					
					my $start = (times)[0];
					
					my @data = QC_Buddy::data_setup(\$db,\@stations_broken,\@parameters_broken,\@start_times_broken,\@end_times_broken,$ARGV[$last_element]);
					
					if($data[0] == -1 || $data[0] == 0){ next;} 
					
					print "Quality Control Underway...\n\n"; 
					
					my @obs = QC_Buddy::run($data[0],$data[1],$data[2],$data[3]);
					
					my $end = (times)[0];
	
					printf "Elapsed time: %.2f seconds.\n\n",$end - $start;
					
					my @failed = @{$obs[1]};	# array of observations which have failed buddy check
					Buddy_util::print_data(\@failed,"B",0);
					
					print "\n";
					
					if($ARGV[$last_element+5] eq "flag"){
	
						Flag::write_to_database(\$db,\@failed,"B");
						Flag::write_to_database(\$db,$obs[0],"B");
					}
		
					if($ARGV[$last_element+5] eq "flag2"){
			
						my %missed_obs = Buddy_util::hash_missed_obs($obs[2]);
			
						Flag::update_flags2(\$db,\@stations_broken,\@parameters_broken,\@start_times_broken,\@end_times_broken,"B",\%missed_obs);
						Flag::write_to_database(\$db,\@failed,"B");
					}	
				}
			}
		}
	}
}



###################################################################################################
# Executes a series of trend comparisons within the station. This is especially important to sr/par
# sensors that have a history of drifting over periods of time.
###################################################################################################
sub execute_trend(){

        if($ARGV[1] eq ""){ print "\nusage: -trend [stations...] -parameters [parameters...] -dates [start time] [end time] [distance]\n\n";return}

        use QC_Trend;

        my @input = parse_input();

        #-------------------------------------------------------
        # Give input data better names.
        #-------------------------------------------------------
        my @stations = @{$input[0]};
        my @parameters = @{$input[1]};
        my @start_times = @{$input[2]};
        my @end_times = @{$input[3]};
        my $last_element = $input[4];           # index to the last element given on command-line


        my $parameterRef = @parameters[0]->[0];
        if(($parameterRef eq 'sr') or ($parameterRef eq 'sravg') or ($parameterRef eq 'par') or ($parameterRef eq 'paravg')){
                #print "Start Time : ".$start_times[0]."\n";
                #print "End Time: ".$end_times[0]."\n";
                my $difference = $end_times[0] - $start_times[0];
                #print "Difference: ".$difference."\n";
                if($end_times[0] - $start_times[0] < 100000000){print "\nTime difference not long enough. Choose longer time series!\n";return;}
                if($end_times[0] - $start_times[0] > 120000000){print "\nTime difference is too long. Time Series can only be 1 month!\n";return;}
                my $data;       my $prevyear;	my $all_data;

                $data = QC_Trend::data_setup($db,\@stations,\@parameters,\@start_times,\@end_times);
                $prevyear = QC_Trend::data_setup_prevyear($db,\@stations,\@parameters,\@start_times,\@end_times);
		$all_data = QC_Trend::data_setup_all($db,\@stations,\@parameters,\@start_times,\@end_times);


                my @failed;

                if($data->[0] != -1){

                        @failed = QC_Trend::radiation_trend($data,$prevyear,$all_data,\@parameters);
                        #------------------------------------
                        #       PRINT FAILED OBSERVATIONS
                        #------------------------------------
			
                        if(@{$failed[1]}==0){ print "Everything has passed quality control!\n\n";}
                        else {
                                print "The following ".@{$failed[1]}." observations have failed quality control:\n\n";
                                QC_Range::print_data($failed[1],"W",0);
                        }

			#------------------------------------
			# 	FLAG DATABASE
			#------------------------------------
			if($ARGV[$last_element] eq "flag"){
	
				Flag::write_to_database(\$db,$failed[1],"W");
				Flag::write_to_database(\$db,$failed[0],"W");
                	}
		}
                else{
                print "\nWhoops....it appears you have an error! Try again!\n";
                }
        }
	
	if($parameterRef eq 'pres'){
	
	my %data=QC_Trend::get_p_dat($db,\@stations,\@parameters,\@start_times,\@end_times);
	#QC_Trend::pressure_trend(\%data,\@start_times,\@end_times);
	my @flags=QC_Trend::P_Stat_Test(\%data,\@start_times,\@end_times);
	my @passed=$flags[0];
	my @failed=$flags[1];

	print "Number of Passed Obs: $#passed \n Number of Failed Obs: $#failed \n";

	}


        if($parameterRef eq 'temp'){
	my $data;

        $data = QC_Trend::data_setup($db,\@stations,\@parameters,\@start_times,\@end_times);
	
	my @failed;
        if($data->[0] != -1){

                        @failed = QC_Trend::temperature_trend($data,\@parameters);
                        #------------------------------------
                        #       PRINT FAILED OBSERVATIONS
                        #------------------------------------
			print "Passed: ".@{$failed[0]}."\tFailed: ".@{$failed[1]}."\n";
                        if(@{$failed[1]}==0){print "Everything has passed quality control!\n\n"; QC_Range::print_data($failed[0],"Z",0);}
                        else {
                                print "The following ".@{$failed[1]}." observations have failed quality control:\n\n";
                                QC_Range::print_data($failed[1],"Z",0);
			}

			#------------------------------------
			# 	FLAG DATABASE
			#------------------------------------
			if($ARGV[$last_element] eq "flag"){
	
				Flag::write_to_database(\$db,$failed[1],"Z");
				Flag::write_to_database(\$db,$failed[0],"Z");
			
                        }
                }
        }
}
################################################################################################### 
# Displays range check statistics in tab delimited format.
################################################################################################### 
sub get_range_stats(){
	
	if($ARGV[1] eq ""){ print "\nusage: -getRangeStats [stations] [parameter] [start time] [end time]\n\n";return;}
	
	Range_Stats::range_stats_visualizer(\$db,$ARGV[1],$ARGV[2],$ARGV[3],$ARGV[4]);
}

################################################################################################### 
# Removes any flags that are associated with 'NULL' data, since NULL data should not be flagged.
################################################################################################### 
sub nullify_flags(){
	
	if($ARGV[1] eq ""){ print "\nusage: -nullFlags [stations...] -parameters [parameters...] -dates [start time] [end time]\n\n";return;}
	
	my @input = parse_input();
	
	Flag::remove_null_flags(\$db,$input[0],$input[1]->[0],$input[2]->[0],$input[3]->[0]);
}

################################################################################################### 
# Calculates the quality control statistics needed for the range check.
################################################################################################### 
sub compute_statistics(){
	
	if($ARGV[1] eq ""){ print "\nusage: -statistics [stations...] -parameters [parameters...] -dates [start time] [end time] [day range] [hour range]\n\n";return;}
	
	use Range_Stats;
	
	my @day_ranges;
	my @hour_ranges;
	
	my @input = parse_input();
	my @parameters = Utilities::isolate_needed_parameters($input[1]->[0],$input[1]->[1],1);
	my $counter = $input[4];
	my @parameters;
	
	my $day_range = $ARGV[$counter];
	my $hour_range = $ARGV[$counter + 1];
	
	if($day_range eq "" || $hour_range eq ""){ print "\nMust provide a day and hour range\n\n"; return;}
	
	for(my$i=0;$i<@{$input[0]};$i++){
	
		$day_ranges[$i] = $day_range;
		$hour_ranges[$i] = $hour_range;
		$parameters[$i] = $input[1]->[0];
	}
		
	Range_Stats::run(\$db,$input[0],$input[2],$input[3],\@day_ranges,\@hour_ranges,\@parameters);
}

################################################################################################### 
# Prints a listing of observations which are already flagged in the database.
################################################################################################### 
sub view_qc_flags(){
	
	if($ARGV[1] eq ""){ print "\nusage: -viewQCFlags [stations...] -parameters [parameters...] -dates [start time] [end time] [flag]\n\n";return;}
	
	my $R;
	my $B;
	my $total;
	
	my @data = parse_input();
	
	my @flags = Flag::get_qc_flags(\$db,$data[0],$data[1]->[0],$data[2]->[0],$data[3]->[0],$ARGV[$data[4]]);
	
	if(@flags>0){
	
		print "\nThe following observations are suspect according to the ".$ARGV[$data[4]]." system:\n\n";
	} else {
		print "\nNo observations are flagged as suspect with the ".$ARGV[$data[4]]." system\n\n";
	} 
	
	for(my$i=0;$i<@flags;$i++){
		
		for(my$j=0;$j<@{$flags[$i]};$j++){
		
			print $flags[$i]->[$j]."  ";
		}
		print "\n";
	}
	print "\n";
}

################################################################################################### 
# Perform quality control for precipitation
###################################################################################################
sub execute_rain_qc(){

	if($ARGV[1] eq ""){ print "\nusage: -rain [stations...] -dates [start time] [end time] [check type]"; return;}
	
	use QC_Rain;#####(test.pm)
	
	my @stations;
	my @start_dates;
	my @end_dates;
	
	my $counter = 1;
	
	#"SELECT stat.station,last_qc_precip FROM statmeta AS stat, parameta_hourly AS para WHERE para.precip IS NOT NULL AND stat.has_hourly = 1 AND stat.type != 'BUOY' AND stat.type != 'NOS' AND stat.type != 'CMAN' AND stat.type != 'USCRN' GROUP BY stat.station"
	
	my $query;
	
	#
	# Create an array of stations based that specified on the command-line
	#
	if($ARGV[1] eq "ALL"){
	
		$query =  "SELECT stat.station,last_qc_precip FROM statmeta AS stat, parameta_hourly AS para WHERE para.precip IS NOT NULL AND stat.has_hourly = 1 AND stat.type != 'BUOY' AND stat.type != 'NOS' AND stat.type != 'CMAN' AND stat.type != 'USCRN' GROUP BY stat.station";
	
		$counter++;
		
	} elsif(substr($ARGV[1],-1) eq "*"){
		
		my $network = substr($ARGV[1],0,-1);
		
		$query = "SELECT stat.station,last_qc_precip FROM statmeta AS stat, parameta_hourly AS para WHERE para.precip IS NOT NULL AND stat.type = '$network' GROUP BY stat.station";
		
		$counter++;
	} else {
		while($ARGV[$counter] ne "-dates"){ $stations[$counter-1] = $ARGV[$counter]; $counter++}
		
		goto CONTINUE;
	}
	
	#
	# If each station was not explicitly given on the command-line, must
	# query database to get stations (all stations or a network)
	#
	
	my $result = $db->Query($query);
	my $result_count = $result->numrows;
	my @row;
	
	for(my$i=0;$i<$result_count;$i++){
	
		@row = $result->FetchRow;
		$stations[$i] = $row[0];
	}
	
	CONTINUE:
	
	$counter++;
	#print "Counter Then: ".$counter++."\n";
	
	#
	# get the start and end date from the command line
	# print error if length is not correct
	#
	my $start_date = $ARGV[$counter++]; 	if(length $start_date != 14){ print "start date incorrectly formatted\n"; return;}
	my $end_date = $ARGV[$counter++]; 	if(length $end_date != 14){ print "end date incorrectly formatted\n"; return;}
	my $check = $ARGV[$counter++];		if(($check ne "clog") && ($check ne "intersensor")){print "incorrect test for precipitation...check your syntax!\n";return;}
	#
	# Format dates for the rain quality control
	#
	$start_date = substr($start_date,0,4)."-".substr($start_date,4,2)."-".substr($start_date,6,2)." ".substr($start_date,8,2).":".substr($start_date,10,2).":".substr($start_date,12,2);
	$end_date = substr($end_date,0,4)."-".substr($end_date,4,2)."-".substr($end_date,6,2)." ".substr($end_date,8,2).":".substr($end_date,10,2).":".substr($end_date,12,2);
	#print $start_date."\t".$end_date."\t".$check."\n";
	
	#
	# Duplicate start and end times for every array element
	#
	for(my$i=0;$i<@stations;$i++){ @start_dates[$i] = $start_date; @end_dates[$i] = $end_date;}
	

	if ($check eq "intersensor"){
	print "Run intersensor...\n";
	my @failed_observations = test::run_rain_qc(\@stations,\@start_dates,\@end_dates);##
	use Data::Dumper;
	#print Dumper(@failed_observations);
	
	#print @failed_observations->[0]->[0]."\n";
	if($ARGV[$counter++] eq "flag"){
		use Flag;
		
		my @parameters = ("precip"); ### Prob. need to be changed. 
		my @parameters2= ("precipimpact1"); ###
		#Flag::update_flags(\$db,\@stations,\@parameters,\@start_dates,\@end_dates,"I");
		Flag::write_to_database_precip(\$db,\@failed_observations,"I");  ### Note: Flag.pm was updated!
		#Flag::update_flags(\$db,\@stations,\@parameters2,\@start_dates,\@end_dates,"I");###
		Flag::write_to_database_impact(\$db,\@failed_observations,"I");###
	}
	}else{
	##########
	#TEST CODE
	##########
	#print "Entering Clog Check...\n";
	my @failed_observations_Clog=test::Clog_Check(\@stations,\@start_dates,\@end_dates);
	use Data::Dumper;
	#print Dumper(@failed_observations_Clog);
	#print @failed_observations_Clog->[0]->[0]."\t".@failed_observations_Clog->[0]->[1]."\n";
	###########
	if($ARGV[$counter++] eq "flag"){
		
		use Flag;
		
		my @parameters = ("precip"); ### Prob. need to be changed. 
		my @parameters2= ("precipimpact1"); ###
		my @parameters3= ("Trend"); ###
		#Flag::update_flags(\$db,\@stations,\@parameters,\@start_dates,\@end_dates,"Z");
		Flag::write_to_database_precip(\$db,\@failed_observations_Clog,"Z");  ### Note: Flag.pm was updated!
		#Flag::update_flags(\$db,\@stations,\@parameters2,\@start_dates,\@end_dates,"Z");###
		Flag::write_to_database_impact(\$db,\@failed_observations_Clog,"Z");###

		#Flag::update_flags(\$db,\@stations,\@parameters3,\@start_dates,\@end_dates,"Z");###
		Flag::write_to_database_Clog(\$db,\@failed_observations_Clog,"Z");
	}
	
	}
	


}

################################################################################################### 
# Prints a listing of observations which are already flagged in the database.
################################################################################################### 
sub view_qc_check(){
	
	if($ARGV[1] eq ""){ print "\nusage: -viewQCCheck [stations...] -parameters [parameters...] -dates [start time] [end time] [flag threshold]\n\n";return;}
	
	my @data = parse_input();
	
	my $final_arg; 
	
	if($#ARGV == $data[4]+1){ $final_arg = $ARGV[$data[4]+1];}
	else { $final_arg = -1;}
	
	my @flags = Flag::get_qc_check(\$db,$data[0],$data[1]->[0],$data[2]->[0],$data[3]->[0],$ARGV[$data[4]],$final_arg);
	
	if(@flags>0){ print "\nThe following observations are suspect according to specified threshold:\n\n";
	} else { print "\nNo observations are flagged as suspect according to specified threshold:\n\n";} 
	
	for(my$i=0;$i<@flags;$i++){
		
		for(my$j=0;$j<@{$flags[$i]};$j++){
		
			print $flags[$i]->[$j]."  ";
		}
		print "\n";
	}
	print "\n";
}

################################################################################################### 
# Sends an email to the listed people with the below file attached. This file stores all of the
# qc flags collected over one day for all stations.
################################################################################################### 
sub daily_email(){
	
	my $to_address = 'aaron_sims@ncsu.edu,ryan_boyles@ncsu.edu,asyed@ncsu.edu,spheuser@ncsu.edu,anfrazier@gmail.com,mark_brooks@ncsu.edu';
	my $file = "/home/cronos/qaqc/trunk/daily_report.txt";
	
	Utilities::email($file,$to_address);
}

################################################################################################### 
# Performs the range check again after recalculating the climatological range statistics and replacing
# all of the failing qc flags with passing ones.
################################################################################################### 
sub repair_range(){

	my @input = parse_input();
	my $counter = $input[4];
	
	# replace all of the failing qc flags with passing ones.
	Flag::replace_flags(\$db,$input[0],$input[1]->[0],$input[2]->[0],$input[3]->[0],"R3","R0");
	Flag::replace_flags(\$db,$input[0],$input[1]->[0],$input[2]->[0],$input[3]->[0],"R2","R0");
	Flag::replace_flags(\$db,$input[0],$input[1]->[0],$input[2]->[0],$input[3]->[0],"R1","R0");
	
	my $old_start_time = $input[2]->[0];
	my $old_end_time = $input[3]->[0];
	
	# adjust the command-line arguments so that the command '-statistics' can be run
	$ARGV[$counter] = 3;
	$ARGV[$counter + 1] = 1;
	$ARGV[$counter - 2] = substr($old_start_time,4,6);
	$ARGV[$counter - 1] = substr($old_end_time,4,6);
	
	print "\n";
	
	compute_statistics();	# recalculate the climatological statistics
	
	# adjust the command-line arguments so that the command '-execute_range_check' will run and replace flags
	$ARGV[$counter] = "flag";
	$ARGV[$counter - 2] = $old_start_time;
	$ARGV[$counter - 1] = $old_end_time;
	
	execute_range_check();
}

################################################################################################### 
# Processes command-line arguments beginning at argument '1' by organizing them into an array of
# stations, an array of parameters, a start time and end time, and the index of the last command-line
# argument. The format is as follows:
#
#	-[command] [ALL OR a network marked with * (e.g. ASOS*) OR a list of stations]
#	-parameters [ALL or a list of parameters
#	-dates [start date and end date (YYYYMMDDHHMMSS)]
#
# All of these items are typed on the command-line on the same line. The arguments marked with
# a '-' separate the station, parameters, and times and allow function to distinguish among these three.
#
# Examples:
#
# perl QC.pl -range ALL -parameters temp -dates 20070312140000 20070314011500 (perform range check for temperature for all stations)
# perl QC.pl -buddy ECONET* -parameters ALL -dates 20070312140000 20070314011500 (perform buddy check for all parameters for ECONET)
#
# Note that this function does not perform any quality control, but rather is used to interface between
# the command-line and the other functions in this file.
#
# @params - command line arguments
# @return - arrays of stations, parameters, start times, end times, and index of last command-line argument
################################################################################################### 
sub parse_input(){

	my @stations;		# will contain array of stations from command-line		
	my @parameters;		# will contain array of parameters from command-line
	my @start_times;	# will contain array of start times from command-line
	my @end_times;		# will contain array of end times from command-line
	my $counter = 1;	# counts the number of command-line arguments
	my $offset = $counter;	# temporarily stores the command-line argument parameters
	my @parameta;		# will store information about the parameters (static ranges, whether or not to use range check/buddy check
	
	if($ARGV[$counter] eq "-parameters" || $ARGV[$counter] eq ""){ die "\nNo stations selected\n\n";}
	
	#------------------------------------
	# 	LOAD STATIONS
	#------------------------------------
	
	#-------------------------------------------------------
	# If the station section on the command-line ends with '*', 
	# a single network of stations has been selected
	#-------------------------------------------------------
	if(substr($ARGV[$counter],-1) eq "*"){
		
		my @types = substr($ARGV[1],0,-1);			# store the station network
		@stations = DataExtractor::load_stations(\$db,\@types);	# get the stations within this network
		$counter++;						# increment counter to next command
		
		# the next argument should now be '-parameters'
		if($ARGV[$counter] ne "-parameters"){ die "\nMust insert '-parameters' to specify parameters\n\n";}
	
	#-------------------------------------------------------
	# If the station section on the command-line is 'ALL',
	# load all stations from all networks.
	#-------------------------------------------------------	
	} elsif($ARGV[$counter] eq "ALL"){
	
		my @types = ("ALL");		# get station types
		@stations = DataExtractor::load_stations(\$db,\@types);	# load all stations
		$counter++;						# increment counter to next command
		
		# the next argument should now be '-parameters'
		if($ARGV[$counter] ne "-parameters"){ die "\nMust insert '-parameters' to specify parameters\n\n";}
	
	#-------------------------------------------------------
	# Otherwise, the command-line should contain a list of
	# station IDs. Collect them within an array.
	#-------------------------------------------------------
	} else {
	
		while($ARGV[$counter] ne "-parameters"){			# '-parameters' marks the end of the station IDs
		
			$stations[$counter - $offset] = $ARGV[$counter];	# store station IDs
			
			# If '-parameters' was not entered on the command-line 
			# in the correct location, output an error message
			if($ARGV[$counter] eq ""){ die "\nMust insert '-parameters' to specify parameters\n\n";}
			
			$counter++;
		}
	}
	
	$counter++;
	
	# If '-dates' was not entered on the command-line 
	# in the correct location, output an error message
	if($ARGV[$counter] eq "-dates" || $ARGV[$counter] eq ""){ die "\nNo parameters selected\n\n";}
	
	$offset = $counter;
	
	@parameta = DataExtractor::load_parameters(\$db);	# get all parameters and parameta
	
	#------------------------------------
	# 	LOAD PARAMETERS
	#------------------------------------
	
	#-------------------------------------------------------
	# If the parameter section on the command-line is 'ALL',
	# load all parameters.
	#-------------------------------------------------------
	if($ARGV[$counter] eq "ALL"){ 
		
		@parameters = @parameta;	# use all parameters
		$counter++;
		
		# the next argument must be 'dates'
		if($ARGV[$counter] ne "-dates"){ die "\nMust insert '-dates' to specify time period\n\n";return;}
	
	#-------------------------------------------------------
	# Otherwise, use the parameters listed on the command-line.
	#-------------------------------------------------------
	} else {
		my @new_array0; my @new_array1; my @new_array2; my @new_array3;
		
		$parameters[0] = \@new_array0; $parameters[1] = \@new_array1;
		$parameters[2] = \@new_array2; $parameters[3] = \@new_array3;
		
		while($ARGV[$counter] ne "-dates"){	# store parameters until '-dates' is found
			
			if($ARGV[$counter] eq ""){ die "\nMust insert '-dates' to specify time period\n\n";}
			
			my $parameter = $ARGV[$counter];
			
			for(my$i=0;$i<@{$parameta[0]};$i++){
				
				if($parameter eq $parameta[0]->[$i]){
					
					push(@{$parameters[0]},$parameta[0]->[$i]);
					push(@{$parameters[1]},$parameta[1]->[$i]);
					push(@{$parameters[2]},$parameta[2]->[$i]);
					push(@{$parameters[3]},$parameta[3]->[$i]);
					push(@{$parameters[4]},$parameta[4]->[$i]);
					
					$i = @{$parameta[0]};
				}
			}
			$counter++;
		}
	}
	
	$counter++;
	
	# store start dates and end dates
	if($ARGV[$counter] eq ""){ die "\nMissing start date\n\n";} 
	if(length $ARGV[$counter] != 14 && $ARGV[0] ne "-statistics" && $ARGV[0] ne "-rangeRepair"){ die "\nStart date incorrectly formatted. Use 'YYYYMMDDHHMMSS'\n\n";}
	if($ARGV[$counter+1] eq ""){ die "\nMissing end date\n\n";} 
	if(length $ARGV[$counter+1] != 14 && $ARGV[0] ne "-statistics" && $ARGV[0] ne "-rangeRepair"){ die "\nEnd date incorrectly formatted. Use 'YYYYMMDDHHMMSS'\n\n";}
	
	#------------------------------------
	# 	LOAD TIMES
	#------------------------------------
	for(my$i=0;$i<@stations;$i++){ $start_times[$i] = $ARGV[$counter];$end_times[$i] = $ARGV[$counter+1];}
	
	$counter+=2;
	
	return (\@stations,\@parameters,\@start_times,\@end_times,$counter);	
}

