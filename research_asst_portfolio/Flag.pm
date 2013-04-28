package Flag;

###################################################################################################
# GENERAL DESCRIPTION
#
# Manages quality control flags within the database.
#
#
#

###################################################################################################

use QueryConstructor;
use strict;

###################################################################################################
# Returns an array with all of the observations which are already flagged in the database based on
# the given flagging system.
#
# @return - an array of observations which have been flagged by the given flagging system
###################################################################################################
sub get_qc_flags($$$$$$){
	
	my $db = $_[0];			# database reference
	my $stations = $_[1];		# array reference of stations
	my $parameters = $_[2];		# array reference of parameters
	my $start_time = $_[3];		# single start time
	my $end_time = $_[4];		# single end time
	my $flag = $_[5];		# flagging system to look for (e.g. 'R')
	
	my @output;			# array of flagged observations
	
	# create and issue query
	my $query = QueryConstructor::get_qc_flags($stations,$parameters,$start_time,$end_time);
	my $result = $$db->Query($query);
	my $row_count = $result->numrows;
	
	# if no observations were returned by query, print error message and exit subroutine
	if($row_count==0){ die "\nNo observations available for specified stations, parameters, and times.\n\n";}
	
	my @row;			# will store single row of a query
	my $good_flag = $flag."0";	# by convention, the passing QC flag ends with a '0' (e.g. 'B0')
	
	# loop through every row
	for(my$i=0;$i<$row_count;$i++){
	
		@row = $result->FetchRow;	# get a query row
		
		# The elements in each row alternate between observed values and flags. If an
		# observed value is flagged with a failing flag, store it for output.
		for(my$j=2;$j<@row;$j+=2){
		
			if($row[$j+1] ne "" && ($row[$j+1] =~ m/$flag/ && $row[$j+1] !~ m/$good_flag/ || $row[$j+1] =~ m/B/ && $row[$j+1] !~ m/B0/)){
			
				my @new_array = ($row[$j+1],$row[0],$row[1],$parameters->[($j-2)/2],$row[$j]);
				push(@output,\@new_array);
			}
		}
	}

	return @output;
}

###################################################################################################
# Returns an array with all of the observations which are already flagged in the database based on
# the given flagging system.
#
# @return - an array of observations which have been flagged by the given flagging system
###################################################################################################
sub get_qc_check($$$$$$$){
	
	my $db = $_[0];			# database reference
	my $stations = $_[1];		# array reference of stations
	my $parameters = $_[2];		# array reference of parameters
	my $start_time = $_[3];		# single start time
	my $end_time = $_[4];		# single end time
	my $threshold = int $_[5];
	my $threshold_high = int $_[6];
	
	my @output;			# array of flagged observations
	
	if($threshold_high==-1){ $threshold_high = 5;}
	
	# create and issue query
	my $query = QueryConstructor::get_qc_check($stations,$parameters,$start_time,$end_time);
	my $result = $$db->Query($query);
	my $row_count = $result->numrows;
	
	# if no observations were returned by query, print error message and exit subroutine
	if($row_count==0){ die "\nNo observations available for specified stations, parameters, and times.\n\n";}
	
	my @row;			# will store single row of a query
	
	# loop through every row
	for(my$i=0;$i<$row_count;$i++){
	
		@row = $result->FetchRow;	# get a query row
		
		# The elements in each row alternate between observed values and flags. If an
		# observed value is flagged with a failing flag, store it for output.
		for(my$j=2;$j<@row;$j+=2){
		
			if($row[$j+1] ne "" && $row[$j+1] >= $threshold && $row[$j+1] <= $threshold_high){
			
				my @new_array = ($row[$j+1],$row[0],$row[1],$parameters->[($j-2)/2],$row[$j]);
				push(@output,\@new_array);
			}
		}
	}

	return @output;
}

###################################################################################################
# Writes a flag to the database. If there is already a flag written in the given location, it will
# concatenate it to the existing flag(s). Using range check as an example, if there is already an 
# 'R' flag in the database, it will be replaced. (e.g. if an R1 is in the database an the new flag 
# is R2, the R1 will be replaced with an R2. This function is used for automated flagging.
###################################################################################################
sub addFlag($$$$$){
	
	my $db = $_[0];		# database reference
	my $station = $_[1];	# single station
	my $parameter = $_[2];	# single parameter
	my $time = $_[3];	# single observation time (YYYYMMDDHHMMSS)
	my $flag = $_[4];	# the name of the flag
	
	my $flagging_system = substr($flag,0,1);	# flagging system (e.g. 'R' or 'B')
	
	my $newFlagSet = '';
	my $query = "SELECT ".$parameter."flag FROM hourly WHERE station = '".$station."' AND ob = '".$time."'";
	
	my $queryConn = $$db->Query($query);
	my @queryRow = $queryConn->FetchRow;
	
	# if the new flag does not match the old flag, must alter flag column
	if($queryRow[0] !~ m/$flag/){
	
		# if there is already an 'R' in the flag column, replace it with the new flag
		if($queryRow[0] =~ m/$flagging_system/){
		
			$queryRow[0] =~ s/$flagging_system./$flag/;
		
			$newFlagSet = $queryRow[0];
	
		# otherwise, concatenate	
		} else { $newFlagSet = $queryRow[0].$flag;}
		
		my $query = "UPDATE hourly SET ".$parameter."flag = '".$newFlagSet."' WHERE station = 
		'".$station."' AND ob = '".$time."' AND ".$parameter." IS NOT NULL";
		
		$$db->Query($query);
	}	
}

###################################################################################################
# Inserts flags into the database for a groups of stations and parameters. The new flag is concatenated
# with any existing flag. Note that even if a station does not report a given parameter, it will
# be flagged.
###################################################################################################
sub insert_flags($$$$$$){

	my $db = $_[0];		# reference to database
	my $stations = $_[1];	# reference to array of stations
	my $parameters = $_[2];	# reference to array of parameter
	my $start_time = $_[3];	# start time (YYYYMMDDHHMMSS)
	my $end_time = $_[4];	# end time (YYYYMMDDHHMMSS)
	my $new_flag = $_[5];	# string of flag to be inserted
	
	my $station_count = @{$stations};
	my $parameter_count = @{$parameters};
	
	# for each station
	for(my$i=0;$i<$station_count;$i++){
		
		# for each parameter
		for(my$j=0;$j<$parameter_count;$j++){ manual_flag($db,$stations->[$i],$parameters->[$j],$new_flag,$start_time,$end_time);}
	}
}

###################################################################################################
# Replaces a flag in the database for a groups of stations and parameters. The old flag is removed
# and the new flag is put in its place.
###################################################################################################
sub replace_flags($$$$$$$){

	my $db = $_[0];		# reference to database
	my $stations = $_[1];	# reference to array of stations
	my $parameters = $_[2];	# reference to array of parameter
	my $start_time = $_[3];	# start time (YYYYMMDDHHMMSS)
	my $end_time = $_[4];	# end time (YYYYMMDDHHMMSS)
	my $old_flag = $_[5];	# flag to be replaced
	my $new_flag = $_[6];	# flag to replace old flag

	my $station_count = @{$stations};
	my $parameter_count = @{$parameters};
	
	# for each station
	for(my$i=0;$i<$station_count;$i++){
		
		# for each parameter
		for(my$j=0;$j<$parameter_count;$j++){ replace_flag($db,$stations->[$i],$parameters->[$j],$old_flag,$new_flag,$start_time,$end_time);}
	}

}

###################################################################################################
# Removes a flag from the database for a given group of stations and parameters.
###################################################################################################
sub remove_flags($$$$$$){
	
	my $db = $_[0];		# reference to database
	my $stations = $_[1];	# array reference of stations
	my $parameters = $_[2];	# array reference of parameters
	my $start_time = $_[3]; # start time (YYYYMMDDHHMMSS)
	my $end_time = $_[4];	# end time (YYYYMMDDHHMMSS)
	my $old_flag = $_[5];	# flag to be removed

	my $station_count = @{$stations};
	my $parameter_count = @{$parameters};
	
	# for each station
	for(my$i=0;$i<$station_count;$i++){
		
		# for each parameter
		for(my$j=0;$j<$parameter_count;$j++){ replace_flag($db,$stations->[$i],$parameters->[$j],$old_flag,"",$start_time,$end_time);}
	}
}

###################################################################################################
# Replaces a flag for the given station and parameter and time frame.
###################################################################################################
sub replace_flag(){
	
	my $db = $_[0];		# reference to database
	my $station = $_[1];	# single station
	my $parameter = $_[2];	# single parameter
	my $oldFlag = $_[3];	# flag to be replaced
	my $newFlag = $_[4];	# replacement flag
	my $beginTime = $_[5];	# start time (YYYYMMDDHHMMSS)
	my $endTime = $_[6];	# end time (YYYYMMDDHHMMSS) (optional)
	
	# make sure the date has enough characters to be valid
	if(length $beginTime != 14 || length $beginTime != 14){ print "The observation times are not formatted correctly\n"; die;} 
	
	# make sure the start time happens before the end time
	if($endTime ne "" && $beginTime > $endTime){ print "End time must be greater than begin time\n"; die;}
	
	# make sure the flag is not too long (I know of no flags that are longer than two characters)
	#if(length $oldFlag > 2 || length $newFlag > 2){ print "Are you sure you want a flag with more than two characters?\n"; die;} 
	
	# if the replacement flag is an empty string, the flag is actually being removed
	if($newFlag ne ""){ print "replacing ".$parameter."flag '".$oldFlag."' with '".$newFlag."' for ".$station." from ".$beginTime." to ".$endTime."\n";} 
	else { print "removing ".$parameter."flag '".$oldFlag."' for ".$station." from ".$beginTime." to ".$endTime."\n";}
		
	my $query = "UPDATE hourly SET ".$parameter."flag = REPLACE(".$parameter."flag,'".$oldFlag."','".$newFlag."') WHERE station = '".$station."' AND ob >= '".$beginTime."' AND ob <= '".$endTime."'";
	
	$$db->Query($query);
}

###################################################################################################
# Manually inserts the given flag for the given station, parameter, and time frame.
#
###################################################################################################
sub manual_flag(){
	
	my $db = $_[0];		# reference to database
	my $station = $_[1];	# single station
	my $parameter = $_[2];	# single parameter
	my $flag = $_[3];	# the flag to insert (i.e. 'R2')
	my $startTime = $_[4];	# start time (YYYYMMDDHHMMSS)
	my $endTime = $_[5];	# end time (YYYYMMDDHHMMSS) (optional)
	
	# make sure the flag is not too long (I know of no flags that are longer than two characters)
	if(length $flag > 2){ print "Are you sure you want a flag with more than two characters?\n"; die;}
	
	# make sure the start time and end time are the correct length
	if(length $startTime != 14 || length $endTime != 14){ print "Dates are not formatted correctly"; die;}
	
	my $query;
		
	# make sure the start time happens before the end time
	if($startTime <= $endTime){
			
		print "inserting '".$flag."' into ".$parameter."flag for ".$station." from ".$startTime." to ".$endTime."\n";	
		$query = "UPDATE hourly SET ".$parameter."flag = CONCAT(IF(".$parameter."flag IS NULL,'',".$parameter."flag),'".$flag."') WHERE station = '".$station."' AND ob >= '".$startTime."' AND ob <= '".$endTime."' AND (".$parameter."flag NOT REGEXP '".$flag."' OR ".$parameter."flag IS NULL)";
			
	} else { print "start time must be earlier than end time\n"; die;}
	
	$$db->Query($query);
}

################################################################################################### 
# Writes flags to the database for a given set of flagged observations. The data input is formatted
# as an array of references to arrays containing information about the observation to flag. The
# following demonstrates the format for the input data:
#
#	ref1 -> <failure level> <station>  <ob time (YYYYMMDDHHMMSS)>  <parameter>
#	ref2 -> <failure level> <station>  <ob time (YYYYMMDDHHMMSS)>  <parameter>
#
# Note that there may be more information associated with each reference, as long as it comes after
# the required fields.
################################################################################################### 
sub write_to_database($$$){
	
	my $db = $_[0];		# reference to database
	my $data = $_[1];	# reference to data
	my $flag = $_[2];	# flag to use (e.g. 'R')
	
	my $count = @{$data};
	my $current;
	my $full_flag;
	
	for(my$i=0;$i<$count;$i++){
	
		$current = $data->[$i];
		
		$full_flag = $flag.($current->[0]);
		
		Flag::addFlag($db,$current->[1],$current->[3],$current->[2],$full_flag);
	}
}

################################################################################################### 
# Writes flags to the database for a given set of flagged observations. The data input is formatted
# as an array of references to arrays containing information about the observation to flag. The
# following demonstrates the format for the input data:
#
#	ref1 -> <failure level precip> <impact> <station>  <ob time (YYYYMMDDHHMMSS)>  <parameter>
#	ref2 -> <failure level precip> <impact> <station>  <ob time (YYYYMMDDHHMMSS)>  <parameter>
#
# Note that there may be more information associated with each reference, as long as it comes after
# the required fields.
#
# !!!!!!!!!!!!!!!!NEW!!!!!!!!!!!!!!!
################################################################################################### 
sub write_to_database_precip($$$){
	
	my $db = $_[0];		# reference to database
	my $data = $_[1];	# reference to data
	my $flag = $_[2];	# flag to use (e.g. 'R')
	
	my $count = @{$data};
	my $current;
	my $full_flag;
	
	for(my$i=0;$i<$count;$i++){
	
		$current = $data->[$i];

		use Data::Dumper; ###
		print Dumper($current); ###

		$full_flag = $flag.($current->[0]);
		#print "Full Flag: ".$full_flag."\n";
		
		Flag::addFlag($db,$current->[2],"precip",$current->[3],$full_flag);
	}
}

################################################################################################### 
# Writes flags to the database for a given set of flagged observations. The data input is formatted
# as an array of references to arrays containing information about the observation to flag. The
# following demonstrates the format for the input data:
#
#	ref1 -> <failure level precip> <impact> <station>  <ob time (YYYYMMDDHHMMSS)>  <parameter>
#	ref2 -> <failure level precip> <impact> <station>  <ob time (YYYYMMDDHHMMSS)>  <parameter>
#
# Note that there may be more information associated with each reference, as long as it comes after
# the required fields.
#
# !!!!!!!!!!!!!!!!NEW!!!!!!!!!!!!!!!
################################################################################################### 
sub write_to_database_impact($$$){
	
	my $db = $_[0];		# reference to database
	my $data = $_[1];	# reference to data
	my $flag = $_[2];	# flag to use (e.g. 'R')
	
	my $count = @{$data};
	my $current;
	my $full_flag;

	
	for(my$i=0;$i<$count;$i++){
		$current = $data->[$i];
		$full_flag = $flag.($current->[1]);

		#use Data::Dumper; ###
		#print Dumper($current); ###
		#print "Full Flag: ".$full_flag."\n"; ###

		Flag::addFlag($db,$current->[2],"impactprecip1",$current->[3],$full_flag);
	}
}

sub write_to_database_Clog($$$){
	my $db = $_[0];		# reference to database
	my $data = $_[1];	# reference to data
	my $flag = $_[2];	# flag to use (e.g. 'R')

	my $count = @{$data};
	my $current;
	my $full_flag;

	print $count;
	for(my$i=0;$i<$count;$i++){
	
		$current = $data->[$i];
		
		my $full_flag_Gauge = $flag.($current->[0]);
		my $full_flag_Impact= $flag.($current->[1]);
		#use Data::Dumper;
		#print Dumper($current);
		#print "My name is...".$current->[2]."  the date of failure is...  ".$current->[3]."  with flag of  ".$full_flag_Impact."  and  ".$full_flag_Gauge."\n";
		
		Flag::addFlag($db,$current->[2],"Impact_Precip_Trend",$current->[3],$full_flag_Impact); ####Change Param names!
		Flag::addFlag($db,$current->[2],"Precip_Trend",$current->[3],$full_flag_Gauge);####Change Param names!
	}

}

###################################################################################################
# For each station and parameter given between the start and end time, alter the flag column such
# that it appears to pass quality control.
#
# @param0 - reference to database
# @param1 - array reference of stations
# @param2 - array reference of parameters
# @param3 - array reference of start times
# @param4 - array reference of end times
# @param5 - flag to insert (e.g. 'R')
###################################################################################################
sub update_flags($$$$$$){
	
	my $db = $_[0];
	my $count = @{$_[2]};
	my $query;
	
	for(my$i=0;$i<$count;$i++){
	
		$query = QueryConstructor::insert_pass_flags($_[1],$_[2]->[$i],$_[3],$_[4],$_[5]);
		$$db->Query($query);
	}
}

###################################################################################################
# For each station and parameter given between the start and end time, alter the flag column such
# that it appears to pass quality control (e.g. insert 'B0' or 'R0' into all cells)
#
# @param0 - reference to database
# @param1 - array reference of stations
# @param2 - array reference of parameters
# @param3 - array reference of start times
# @param4 - array reference of end times
# @param5 - flag to insert (e.g. 'B')
# @param6 - data which should not be flagged
###################################################################################################
sub update_flags2($$$$$$$){
	
	my $db = $_[0];
	my $count = @{$_[2]};
	my $parameter_hash = $_[6];	# data which should not be flagged
	my $query;
	
	my $station_hash;
	
	for(my$i=0;$i<$count;$i++){
		
		$station_hash = $parameter_hash->{$_[2]->[$i]};
		
		$query = QueryConstructor::insert_some_pass_flags($_[1],$_[2]->[$i],$_[3],$_[4],$_[5],5,$station_hash,"R4");
		
		$$db->Query($query);
	}
}

###################################################################################################
# If a parameter value is NULL, but there is a flag associated with it (i.e. observation should have
# no flag), remove the flag.
###################################################################################################
sub remove_null_flags($$$$$){
	
	my $db = $_[0];		# reference to database
	my $stations = $_[1];	# array reference of stations
	my $parameters = $_[2]; # array reference of parameters
	my $begin_time = $_[3];	# array reference of start times
	my $end_time = $_[4];	# array reference of end times
	
	my $query;
	
	for(my$i=0;$i<@{$stations};$i++){
	
		for(my$j=0;$j<@{$parameters};$j++){
		
			$query = QueryConstructor::remove_null_flags($stations->[$i],$parameters->[$j],$begin_time,$end_time);
			print "removing null flags at ".$stations->[$i]." for ".$parameters->[$j]."\n";
			$$db->Query($query);
		}
	}
}

1;
