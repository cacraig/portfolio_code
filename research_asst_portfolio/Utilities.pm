                                                                     
                                                                     
                                                                     
                                             
#!/usr/bin/perl

package Utilities;

###################################################################################################
# GENERAL DESCRIPTION
#
# This module performs a wide variety of non-database calculations and data manipulation for the
# higher level quality control modules
#

####################################################################################################

use strict;
use MIME::Lite;

my @days_in_month = (31,28,31,30,31,30,31,31,30,31,30,31);
my @julian_days = (0,31,60,91,121,152,182,213,244,274,305,335);

###################################################################################################
# Given a date of the format YYYY-MM-DD HH:MM:SS, rounds to the nearest hour. For example, for an 
# input of '2004-10-23 13:35:00', the output would be '2004-10-23 14:00:00'.
#
# @param - YYYY-MM-DD HH:MM:SS
# @return - YYYY-MM-DD HH:00:00 (rounded to nearest hour)
###################################################################################################
sub round_date_string($){
	
	my $date = $_[0];
	my $minute = substr($date,14,2);
	
	#if($minute < 30){
		
	#	return substr($date,0,14)."00:00";	
	#}
	
	my $year = int substr($date,0,4);
	my $month = int substr($date,5,2);
	my $day = int substr($date,8,2);
	my $hour = int substr($date,11,2);
	my $daysInMonth;

	if($month==2 && $year % 4 == 0){ $daysInMonth = 29;}
	else { $daysInMonth = $days_in_month[$month-1];}
	
	$hour++;
	if($hour > 23){ $day++; $hour = $hour - 24}
	if($day > $daysInMonth){ $month++; $day = $day - $daysInMonth;}
	if($month > 12){ $year++; $month = $month - 12;}
	
	if($hour < 10){ $hour = "0".$hour;}
	if($day < 10){ $day = "0".$day;}
	if($month < 10){ $month = "0".$month;}
	
	return $year."-".$month."-".$day." ".$hour.":00:00";	
}

###################################################################################################
# Given a date of the format YYYYMMDDHHMMSS, rounds to the nearest hour. For example, for an input 
# of '20041023133500', the output would be '20041023140000'.
#
# @param - YYYYMMDDHHMMSS
# @return - YYYYMMDDHH0000 (rounded to nearest hour)
###################################################################################################
sub round_date_int($){
	
	my $date = $_[0];
	my $minute = substr($date,10,2);
	
	if($minute < 30){
		
		return substr($date,0,10)."0000";	
	}
	
	my $year = int substr($date,0,4);
	my $month = int substr($date,4,2);
	my $day = int substr($date,6,2);
	my $hour = int substr($date,8,2);
	my $daysInMonth;
	
	if($month==2 && $year % 4 == 0){ $daysInMonth = 29;}
	else { $daysInMonth = $days_in_month[$month-1];}
	
	$hour++;
	if($hour > 23){ $day++; $hour = $hour - 24}
	if($day > $daysInMonth){ $month++; $day = $day - $daysInMonth;}
	if($month > 12){ $year++; $month = $month - 12;}
	
	if($hour < 10){ $hour = "0".$hour;}
	if($day < 10){ $day = "0".$day;}
	if($month < 10){ $month = "0".$month;}
	
	return $year.$month.$day.$hour."0000";	
}

###################################################################################################
# Given a date of the format YYYYMMDDHHMMSS, rounds to the nearest hour. For example, for an input 
# of '20041023133500', the output would be '20041023140000'.
#
# @param - YYYYMMDDHHMMSS
# @return - YYYYMMDDHH0000 (rounded to nearest hour)
###################################################################################################
sub round_date($){
	
	my $date = $_[0];
	my $minute = substr($date,10,2);
	
	my $year = int substr($date,0,4);
	my $month = int substr($date,4,2);
	my $day = int substr($date,6,2);
	my $hour = int substr($date,8,2);
	my $daysInMonth;
	
	if($month==2 && $year % 4 == 0){ $daysInMonth = 29;}
	else { $daysInMonth = $days_in_month[$month-1];}
	
	$hour++;
	if($hour > 23){ $day++; $hour = $hour - 24}
	if($day > $daysInMonth){ $month++; $day = $day - $daysInMonth;}
	if($month > 12){ $year++; $month = $month - 12;}
	
	if($hour < 10){ $hour = "0".$hour;}
	if($day < 10){ $day = "0".$day;}
	if($month < 10){ $month = "0".$month;}
	
	return $year.$month.$day.$hour."0000";	
}


###################################################################################################
# Given a date of the format YYYY-MM-DD HH:MM:SS, rounds to the nearest hour. For example, for an 
# input of '2004-10-23 13:35:00', the output would be '2004-10-23 14:00:00'.
#
# @param - YYYY-MM-DD HH:MM:SS
# @return - YYYY-MM-DD HH:00:00 (truncated to the HH hour)
###################################################################################################

sub trunc_date_string($){

	my $date = $_[0];
	my $minute = substr($date,14,2);
	
	my $year = int substr($date,0,4);
	my $month = int substr($date,5,2);
	my $day = int substr($date,8,2);
	my $hour = int substr($date,11,2);

	if($hour < 10){ $hour = "0".$hour;}
	if($day < 10){ $day = "0".$day;}
	if($month < 10){ $month = "0".$month;}
	
	return $year."-".$month."-".$day." ".$hour.":00:00";



}
###################################################################################################
# Given a date of the format YYYYMMDDHHMMSS, truncate date to current hour. For example, for an input
# of '20041023133500' , the output would be '20041023130000'.
#
# @param - YYYYMMDDHHMMSS
# @return - YYYYMMDDHH0000 (truncated to the HH hour)
###################################################################################################

sub trunc_date_int($){
	my $date = $_[0];
	my $minute = substr($date,10,2);
	
	my $year = int substr($date,0,4);
	my $month = int substr($date,4,2);
	my $day = int substr($date,6,2);
	my $hour = int substr($date,8,2);
	#print "Year: $year \t Month: $month \t Day: $day \t Hour: $hour\n";

	if($hour < 10){ $hour = "0".$hour;}
	if($day < 10){ $day = "0".$day;}
	if($month < 10){ $month = "0".$month;}

	return $year.$month.$day.$hour."0000";


}
######################################################################################################################
#Day_Subtract($)
#use: Subtracts 15 days off of passed date. 
#Format: YYYY-MM-DD-hh
######################################################################################################################

sub Day_Subtract($){
	my $date=$_[0];
	my $year = int substr($date,0,4);
	my $month = int substr($date,5,2);
	my $day = int substr($date,8,2);
	my $hour = int substr($date,11,2);
	my $daysInMonth;
	if($month==2 && $year % 4 == 0){ $daysInMonth = 29;}	# account for leap years
	else { $daysInMonth = $days_in_month[$month-1];}
	$day=$day-15;
	
	if($day<=0){	
		$month--;
		if($month==2 && $year % 4 == 0){ $day = 29+$day;}
			else {$day=$days_in_month[$month-1]+$day;}
		if($month==0){$month=12;$year--;}}

	if($hour < 10){ $hour = "0".$hour;}
	if($day < 10){ $day = "0".$day;}
	if($month < 10){ $month = "0".$month;}

return $year."-".$month."-".$day." ".$hour.":00:00";
}
######################################################################################################################
#Day_Subtract_int($)
#use: Subtracts 6 months off of passed date. 
#Format: YYYYMMDDhhmmss
######################################################################################################################

sub Day_Subtract_int($){
	my $date=$_[0];
	my $year = int substr($date,0,4);
	my $month = int substr($date,4,2);
	my $day = int substr($date,6,2);
	my $hour = int substr($date,8,2);
	my $min=int substr($date,10,2);
	my $daysInMonth;
	if($month==2 && $year % 4 == 0){ $daysInMonth = 29;}	# account for leap years
	else { $daysInMonth = $days_in_month[$month-1];}
	#$year=$year-1;
	$month=$month-6;
	#$day=$day-15;

	if($month<=0){
		$year--;
		$month=$month+12;
		if($month==0){$month=12;$year--;}
		if($day>$days_in_month[$month-1]){
			$day=$days_in_month[$month-1];}}
	
	if($day<=0){	
		$month--;
		if($month==2 && $year % 4 == 0){ $day = 29+$day;}
			else {$day=$days_in_month[$month-1]+$day;}
		if($month==0){$month=12;$year--;}}

	if($hour < 10){ $hour = "0".$hour;}
	if($day < 10){ $day = "0".$day;}
	if($month < 10){ $month = "0".$month;}
	if($min < 10){ $min = "0".$min;}

return $year.$month.$day.$hour.$min."00";

}

########################
#Adds 2 months from date.
#Used in MPE_Precip calculation for periods greater than 2 months. 
########################

sub M2_Add($){
	my $date=$_[0];
	my $year = int substr($date,0,4);
	my $month = int substr($date,5,2);
	my $day = int substr($date,8,2);
	my $hour = int substr($date,11,2);
	my $daysInMonth;
	for(my$i;$i<2;$i++){
	$month=$month+1;
	if($month==2 && $year % 4 == 0){ $daysInMonth = 29;}	# account for leap years
	else { $daysInMonth = $days_in_month[$month-1];}
	if($month>12){$month=1;$year++;$daysInMonth=$days_in_month[$month-1];}
	if($day>$daysInMonth){$day=$daysInMonth;}
	}

	if($hour < 10){ $hour = "0".$hour;}
	if($day < 10){ $day = "0".$day;}
	if($month < 10){ $month = "0".$month;}

return $year."-".$month."-".$day." ".$hour.":00:00";
}



####
##
##
####

sub hour_addition_string($){
my $date = $_[0];
	
	my $year = int substr($date,0,4);
	my $month = int substr($date,5,2);
	my $day = int substr($date,8,2);
	my $hour = int substr($date,11,2);
	my $daysInMonth;
	
	if($month==2 && $year % 4 == 0){ $daysInMonth = 29;}	# account for leap years
	else { $daysInMonth = $days_in_month[$month-1];}
	
	$hour++;	# add an hour

	if($hour>=24){$day++;$hour=0;}
	
	if($day>$daysInMonth){
		$month++;
		$day=01;

		if($month>12){ $month = 01;$year++;}	
	}
	
	if($hour < 10){ $hour = "0".$hour;}
	if($day < 10){ $day = "0".$day;}
	if($month < 10){ $month = "0".$month;}
	
	return $year."-".$month."-".$day." ".$hour.":00:00";
}


###################################################################################################
# Given a date of the format YYYYMMDDHHMMSS or YYYYMMDDHH, returns the date one hour after this date. 
#
#
#@params date (YYYYMMDDHHMMSS or YYYYMMDDHH) 
#@return (date + 1) hour (in YYYYMMDDHH format). 
#
# Used in Rain QC ( in get_impact_data() )
###################################################################################################
sub hour_addition($){
	my $date = $_[0];
	
	my $year = int substr($date,0,4);
	my $month = int substr($date,4,2);
	my $day = int substr($date,6,2);
	my $hour = int substr($date,8,2);
	my $daysInMonth;
	
	if($month==2 && $year % 4 == 0){ $daysInMonth = 29;}	# account for leap years
	else { $daysInMonth = $days_in_month[$month-1];}
	
	$hour++;	# add an hour

	if($hour==24){$day++;$hour=0;}
	
	if($day>$daysInMonth){
		$month++;
		$day=1;

		if($month>12){ $month = 01;$year++;}	
	}
	
	if($hour < 10){ $hour = "0".$hour;}
	if($day < 10){ $day = "0".$day;}
	if($month < 10){ $month = "0".$month;}

	
	
	return $year.$month.$day.$hour;
}

###################################################################################################
# Given a date of the format YYYYMMDDHHMMSS, returns the date one hour before this date.
###################################################################################################
sub hour_subtract($){

	my $date = $_[0];
	
	my $year = int substr($date,0,4);
	my $month = int substr($date,4,2);
	my $day = int substr($date,6,2);
	my $hour = int substr($date,8,2);
	my $daysInMonth;
	
	if($month==2 && $year % 4 == 0){ $daysInMonth = 29;}	# account for leap years
	else { $daysInMonth = $days_in_month[$month-1];}
	
	$hour--;	# subtract an hour
	
	if($hour<0){ $day--;$hour+=24}
	
	if($day<1){
		
		$month--;
		
		if($month<1){ $month = 12;$year--;}
		if($month==2 && $year % 4 == 0){ $day = 29;}
		else { $day = $days_in_month[$month-1];}	
	}
	
	if($hour < 10){ $hour = "0".$hour;}
	if($day < 10){ $day = "0".$day;}
	if($month < 10){ $month = "0".$month;}
	
	return $year.$month.$day.$hour."0000";
}

################################################
#Time difference...Given start and end time, calculate hour difference
#NEW 
#Date Format: YYYYMMDDHHMMSS
#@return: Hour Difference between times
################################################
sub Time_Diff_int($$){
	my $date1 = $_[0];
	my $date2= $_[1];
	my $hours;
	my $days;
	my $time1;my $time2;
	my $year1 = int substr($date1,0,4);
	my $month1 = int substr($date1,4,2);
	my $day1 = int substr($date1,6,2);
	my $hour1 = int substr($date1,8,2);
	#print $year1."  ".$month1."  ".$day1."   ".$hour1."\n";
	my $year2 = int substr($date2,0,4);
	my $month2 = int substr($date2,4,2);
	my $day2 = int substr($date2,6,2);
	my $hour2 = int substr($date2,8,2);
	use Time::Local;
	$time1=timelocal(0,0,$hour1,$day1,($month1-1), ($year1-1900)); #months are 0-11, years 100-999
	$time2=timelocal(0,0,$hour2,$day2,($month2-1), ($year2-1900));
	#print $year2."  ".$month2."  ".$day2."   ".$hour2."\n";
	my $diff=$time2-$time1;
	#$days=int(($diff/3600)/24);
	#$hours=$days*24;
	$hours=int($diff/3600);
	#print "\n".$hours;
	#print $hours;
	return $hours;

		


}

################################################
#Time difference...Given start and end time, calculate minute difference
#NEW 
#Date Format: YYYYMMDDHHMMSS
#@return: minute Difference between times
################################################
sub Time_Diff_int_min($$){
	my $date1 = $_[0];
	my $date2= $_[1];
	my $mins;
	my $days;
	my $time1;my $time2;
	my $year1 = int substr($date1,0,4);
	my $month1 = int substr($date1,4,2);
	my $day1 = int substr($date1,6,2);
	my $hour1 = int substr($date1,8,2);
	my $mins1 = int substr($date1,10,2);
	#print $year1."  ".$month1."  ".$day1."   ".$hour1."\n";
	my $year2 = int substr($date2,0,4);
	my $month2 = int substr($date2,4,2);
	my $day2 = int substr($date2,6,2);
	my $hour2 = int substr($date2,8,2);
	my $mins2 = int substr($date2,10,2);
	use Time::Local;
	$time1=timelocal(0,$mins1,$hour1,$day1,($month1-1), ($year1-1900)); #months are 0-11, years 100-999
	$time2=timelocal(0,$mins2,$hour2,$day2,($month2-1), ($year2-1900));
	#print $year2."  ".$month2."  ".$day2."   ".$hour2."\n";
	my $diff=$time2-$time1;
	#$days=int(($diff/3600)/24);
	#$hours=$days*24;
	$mins=int($diff/60);
	#print "\n".$hours;
	#print $hours;
	return $mins;

		


}


################################################
#Time difference...Given start and end time, calculate hour difference
#NEW
#Date Format: YYYY-MM-DD HH:MM:SS
#@return: Hour Difference between times
################################################
sub Time_Diff($$){
	my $date1 = $_[0];
	my $date2= $_[1];
	my $hours;
	my $days;
	my $time1;my $time2;
	my $year1 = int substr($date1,0,4);
	my $month1 = int substr($date1,5,2);
	my $day1 = int substr($date1,8,2);
	my $hour1 = int substr($date1,11,2);
	#print $year1."  ".$month1."  ".$day1."   ".$hour1."\n";
	my $year2 = int substr($date2,0,4);
	my $month2 = int substr($date2,5,2);
	my $day2 = int substr($date2,8,2);
	my $hour2 = int substr($date2,11,2);
	use Time::Local;
	$time1=timelocal(0,0,$hour1,$day1,($month1-1), ($year1-1900)); #months are 0-11, years 100-999
	$time2=timelocal(0,0,$hour2,$day2,($month2-1), ($year2-1900));
	#print $year2."  ".$month2."  ".$day2."   ".$hour2."\n";
	my $diff=$time2-$time1;
	$days=int(($diff/3600)/24);
	$hours=$days*24;
	#print "\n".$hours;
	#print $hours;
	return $hours;

		


}
###############################
#Modifies MPE date format.
#
###############################
sub mod_date($$){
	my $date = $_[0];
	my $hour = $_[1];
	my $year = int substr($date,0,4);
	my $month = int substr($date,5,2);
	my $day = int substr($date,8,2);

	return $year.$month.$day.$hour."0000";
}



###################################################################################################
# Given a date of the format YYYY-MM-DD HH:MM:SS, returns the date X hours before this date.
#
# @param0 - the date
# @param1 - number of hours to subtract (must be less than 24)
###################################################################################################
sub hour_subtract_string($$){

	my $date = $_[0];
	my $hour_less = $_[1];
	
	my $year = int substr($date,0,4);
	my $month = int substr($date,5,2);
	my $day = int substr($date,8,2);
	my $hour = int substr($date,11,2);
	my $daysInMonth;
	
	if($month==2 && $year % 4 == 0){ $daysInMonth = 29;}	# account for leap years
	else { $daysInMonth = $days_in_month[$month-1];}
	
	$hour-=$hour_less;	# subtract hours
	
	# subtracting hours may require another time element (e.g. the day) to change
	if($hour<0){ $day--;$hour+=24}
	
	if($day<1){
		
		$month--;
		
		if($month<1){ $month = 12;$year--;}
		if($month==2 && $year % 4 == 0){ $day = 29;}
		else { $day = $days_in_month[$month-1];}	
	}
	
	# ensure two digit formatting for output
	if($hour < 10){ $hour = "0".$hour;}
	if($day < 10){ $day = "0".$day;}
	if($month < 10){ $month = "0".$month;}
	
	return $year."-".$month."-".$day." ".$hour.":00:00";
}

###################################################################################################
# Given a list of parameters, returns an array with the given parameters and each parameter's 
# corresponding flag adjacent to it. For example,
#
# ("temp","rh","sr","par") becomes ("temp","tempflag","rh","rhflag",
# "sr","srflag","par","parflag")
#
# @param0 - reference to array of parameters
# @return array of parameters and parameter
###################################################################################################
sub addFlags($){

	my $parameters = $_[0];
	my $count = @{$parameters};
	my @output;
	
	for(my$i=0;$i<$count;$i++){
	
		$output[2*$i] = $parameters->[$i];
		$output[2*$i+1] = $parameters->[$i]."flag";
	}
	
	return @output;
}

###################################################################################################
# Calculates the distance in kilometers between two coordinates using the Haversine formula.
#
# @param0 - lat1
# @param1 - lon1
# @param2 - lat2
# @param3 - lon2
# @return - distance in kilometers
###################################################################################################
sub find_distance($$$$){

	my $Re = 6375;		# earth radius in km
	
	# convert to radians
	my $lat1 = ((2*3.1415) / 360) * $_[0];
	my $lon1 = ((2*3.1415) / 360) * $_[1];
	my $lat2 = ((2*3.1415) / 360) * $_[2];
	my $lon2 = ((2*3.1415) / 360) * $_[3];
	
	# differences
	my $dlat = $lat2 - $lat1;
	my $dlon = $lon2 - $lon1;
	
	my $a = (sin($dlat/2))**2 + cos($lat1) * cos($lat2) * (sin($dlon/2))**2;
	my $c = 2*atan2(sqrt($a),sqrt(1-$a));
	
	return $Re * $c;	
}

###################################################################################################
# Calculates the julian day for a given month and day in order to index some of the arrays. 	
# Note that the index goes by a leap year to keep it consistant from year to year.
#
# @param0 - the month
# @param1 - the day
# @return - the julian day									
###################################################################################################
sub convertGregToJul($$){
	
	return $julian_days[$_[0] - 1] + $_[1];
}

###################################################################################################
# Isolates a groups of elements from an array. The first parameter is the list of items from which
# to choose and the second a parallel array of integers marked with '1' if it should be isolated.
# The output is an array of these isolated parameters. For example, consider the following input:
#
#	param0	->	temp	rh	dew	ws	wd
#	param1	->	 1	 1	 0	1	 0
#
# The output in this case would be an array with temp, rh, and ws since they are marked with '1'.
#
# @param0 - array reference to any group of elements
# @param1 - array reference to array of integers
# @return - array of isolated elements
###################################################################################################
sub isolate_needed_parameters($$$){

	my $parameters = $_[0];
	my $needed = $_[1];
	my $ones_only = $_[2];
	my @output;
	
	my $count = @{$parameters};
	
	if($ones_only==1){ for(my$i=0;$i<$count;$i++){ if($needed->[$i]==1){ push(@output,$parameters->[$i]);}}}
	elsif($ones_only==0){ for(my$i=0;$i<$count;$i++){ if($needed->[$i]!=0){ push(@output,$parameters->[$i]);}}}
	else { die "\nArgument 3 to 'Utilities::isolate_needed_parameters must be either '0' or '1'\n\n";}
	
	return @output;
}

###################################################################################################
# Given a set of inputs, creates a list seperated by a given delimeter
#
# @param0 - array reference to list
# @param1 - a delimeter
# @param2 - character to go on either side of each list item (e.g. quotes)
# @return a list seperated by a delimeter
###################################################################################################
sub seperated_list($$$){
	
	my $listRef = $_[0];
	my $delimeter = $_[1];
	my $quote = $_[2];
	my $numberOfElements = @{$listRef};
	my $output = "";
	
	for(my$i=0;$i<$numberOfElements-1;$i++){ $output = $output.$quote.$listRef->[$i].$quote.$delimeter;}
	
	$output = $output.$quote.$listRef->[$numberOfElements-1].$quote;
	
	return $output;
}

###################################################################################################
# Formats dates such that there are no -'s, :'s, or whitespace. For example, 2006-03-12 12:35:00 => 
# 20060312123500. This function is useful for comparing order of dates and for creating a standard
# format for substring extraction from dates. Note that the original array is not modified, but 
# rather a copy is made to modify.
#
# @param1 - array reference which contains dates
# @return - array of modified dates
###################################################################################################
sub trim_date($){

	my @array = @{$_[0]};						# create copy of array						
	my $count = @array;						# total number of rows
	
	for(my$i=0;$i<$count;$i++){					# loop through each element
	
		$array[$i] =~ s/-|:| //g;				# remove characters
	}
	
	return @array;
}

###################################################################################################
# Lists all the top of the hour observation times between and including the start and end time 
# given as parameters. For example,between 012514 and 012517, the top of the hour observations would
# be 012514,012515,012516,012517. However, the output is formatted as follows: [julian date for a 
# leap year] * 100 + [hour]. For example, 012514 -> [25]*100 + [14] = 2514. This format permits
# ease of calculation and requires knowledge of whether or not the date is within a leap year to
# translate it to a date during a specific year.
#
# @param0 - start time (MMDDHH)
# @param1 - end time  (MMDDHH)
# @return array of times
###################################################################################################
sub determine_intermediate_hours($$){

	my $start_time = $_[0];
	my $end_time = $_[1];
	
	my @output;
	
	# translate dates to output format
	my $start_julian = Utilities::convertGregToJul(substr($start_time,0,2),substr($start_time,2,2))*100+substr($start_time,4,2);
	my $end_julian = Utilities::convertGregToJul(substr($end_time,0,2),substr($end_time,2,2))*100+substr($end_time,4,2);
	
	# if the start date is earlier than the end date, dates do not cross the year boundary (Dec.31 - Jan.1)
	if($start_julian <= $end_julian){
	
		for(my$i=$start_julian;$i<=$end_julian;$i++){
		
			if(substr($i,-2,2) > 23){ $i = (int($i/100) + 1) * 100;}
			
			push(@output,$i);
		
		}
		
	# if the start date is later than the end date, the year boundary (Dec.31 - Jan.1) is crossed
	} else {
		# go from the start date to Dec.31 at 23 hours
		for(my$i=$start_julian;$i<=36623;$i++){
		
			if(substr($i,-2,2) > 23){ $i = (int($i/100) + 1) * 100;}
			
			push(@output,$i);
		
		}
		
		# go from Jan.1 00 hours to the end date
		for(my$i=100;$i<=$end_julian;$i++){
			
			if(substr($i,-2,2) > 23){ $i = (int($i/100) + 1) * 100;}
			
			push(@output,$i);
		}
	}
	
	return @output;
}

###################################################################################################
# Given a start time and an end time formatted as "YYYYMMDDHHMMSS", lists all of the hours in between.
# The first and last time in this list will use the first and last time given, while every hour in 
# between will use "30" as its minute. For example, a start time of 20070510121400 and an end time 
# of 2007051015450000 will yield 20070510121400 20070510133000 20070510143000 20070510154500.
# This date listing method is most efficient for quality control.
#
# @param0 - start time (YYYYMMDDHHMMSS)
# @param1 - end time (YYYYMMDDHHMMSS)
# @return - list of hours in between start and end time
###################################################################################################
sub list_hours($$){
	
	my $start_date = $_[0];
	my $end_date = $_[1];
	my @output;
	my $days;	# number of days in a month
	
	my $month; my $day; my $hour;			# keeps track of times within the following loops
	my $last_month; my $last_day; my $last_hour;	# keeps track of last times within the following loops
	
	#-------------------------------------------------------
	# Parse input into year, months, days, and hours. The first
	# times will change in the following loops, but the final
	# times will not change.
	#-------------------------------------------------------
	my $first_year = int substr($start_date,0,4);	my $final_year = int substr($end_date,0,4);
	my $first_month = int substr($start_date,4,2);	my $final_month = int substr($end_date,4,2);
	my $first_day = int substr($start_date,6,2);	my $final_day = int substr($end_date,6,2);
	my $first_hour = int substr($start_date,8,2);	my $final_hour = int substr($end_date,8,2);
	
	#-------------------------------------------------------
	# Loop between the first year and the last year.
	#-------------------------------------------------------
	for(my$h=$first_year;$h<=$final_year;$h++){
		
		# if there are multiple years in the period, the last month will be '12' in
		# all but the last year and the first month will be '1' in all but the first year
		if($h!=$first_year){ $first_month = 1;} if($h!=$final_year){ $last_month = 12;} else { $last_month = $final_month;}
		
		#-------------------------------------------------------
		# Loop between the first month and the last month
		#-------------------------------------------------------
		for(my$i=$first_month;$i<=$last_month;$i++){
			
			if($i!=2 || $h%4!=0){ $days = $days_in_month[$i-1];} else { $days = 29;}	# account for leap years
			$month = $i; if($month < 10){ $month = "0".$month;}				# ensure month is two digits long
			
			# if there are multiple months in the period, the last day will be 28,29,30, or 31 in
			# all but the last month and the first day will be '1' in all but the first month
			if($i!=$first_month){ $first_day=1;} if($i!=$final_month || $h!=$final_year){ $last_day = $days;} else { $last_day = $final_day;}
			
			#-------------------------------------------------------
			# Loop between the first day and the last day.
			#-------------------------------------------------------
			for(my$j=$first_day;$j<=$last_day;$j++){
			
				$day = $j; if($day < 10){ $day = "0".$day;}	# ensure day is two digits long
				
				# if there are multiple days in the period, the last hour will be 24 in
				# all but the last day and the first hour will be '1' in all but the first day
				if($j!=$first_day){ $first_hour = 0;} if($j!=$final_day || $i!=$final_month || $h!=$final_year){ $last_hour = 23;} else { $last_hour = $final_hour;}
				
				#-------------------------------------------------------
				# Loop between the first hour and the last hour.
				#-------------------------------------------------------
				for(my$k=$first_hour;$k<=$last_hour;$k++){
			
					$hour = $k; if($hour < 10){ $hour = "0".$hour;}	# ensure hour is two digits long
					push(@output,$h.$month.$day.$hour."3000");	# set minute to '30' for each hour and store calculated time
				}
			}
		}
	}
	
	$output[0] = $start_date;			# first time will always be the given start time
	$output[$#output] = $end_date;			# last time will always be the given end time
	
	return @output;
}


###################################################################################################
# Converts a Julian day and hour (DDDHH) to a Gregorian date (MMDDHH).
#
# @param0 - julian day * 100 + hour
# @return MMDDHH
###################################################################################################
sub translate_date($){

	my $day = int $_[0]/100;
	my $hour = substr($_[0],-2);
	my $newday;
	my $month;
		
	if($day < 32){      $month = 1; $newday = $day} 	# January		
	elsif($day < 61 ){  $month = 2; $newday = $day - 31} 	# February	
	elsif($day < 92 ){  $month = 3; $newday = $day - 60} 	# March
	elsif($day < 122 ){ $month = 4; $newday = $day - 91} 	# April
	elsif($day < 153 ){ $month = 5; $newday = $day - 121} 	# May
	elsif($day < 183 ){ $month = 6; $newday = $day - 152} 	# June
	elsif($day < 214 ){ $month = 7; $newday = $day - 182} 	# July
	elsif($day < 245 ){ $month = 8; $newday = $day - 213} 	# August
	elsif($day < 275 ){ $month = 9; $newday = $day - 244} 	# September
	elsif($day < 306){  $month = 10;$newday = $day - 274} 	# October
	elsif($day < 336){  $month = 11;$newday = $day - 305} 	# November
	elsif($day < 367){  $month = 12;$newday = $day - 335} 	# December
		
	if($month < 10){ $month = "0".$month; }
	if($newday < 10){ $newday = "0".$newday;}
	
	return $month.$newday.$hour;
}

###################################################################################################
# Calculates the Gregorian day for a given Julian day and hour.
#
# @param0 - julian day
# @param1 - hour
# @return - Gregorian date (MMDDHH)									
###################################################################################################
sub convertJulToGreg($$){

	my $day = $_[0];
	my $hour = $_[1];
	my $newday;
	my $month;
		
	if($day < 32){      $month = 1; $newday = $day} 	# January		
	elsif($day < 61 ){  $month = 2; $newday = $day - 31} 	# February	
	elsif($day < 92 ){  $month = 3; $newday = $day - 60} 	# March
	elsif($day < 122 ){ $month = 4; $newday = $day - 91} 	# April
	elsif($day < 153 ){ $month = 5; $newday = $day - 121} 	# May
	elsif($day < 183 ){ $month = 6; $newday = $day - 152} 	# June
	elsif($day < 214 ){ $month = 7; $newday = $day - 182} 	# July
	elsif($day < 245 ){ $month = 8; $newday = $day - 213} 	# August
	elsif($day < 275 ){ $month = 9; $newday = $day - 244} 	# September
	elsif($day < 306){  $month = 10;$newday = $day - 274} 	# October
	elsif($day < 336){  $month = 11;$newday = $day - 305} 	# November
	elsif($day < 367){  $month = 12;$newday = $day - 335} 	# December
		
	if($month < 10){ $month = "0".$month; }
	if($newday < 10){ $newday = "0".$newday;}
	if($hour < 10){ $hour = "0".$hour; }
	
	return $month.$newday.$hour;
}

###################################################################################################
# Send an email with an attachment.
#
# @param0 - name (and path) of file to send
# @param1 - comma seperated string of email addresses
###################################################################################################
sub email($$){
	
	my $from_address = 'qc@capefear.meas.ncsu.edu';
	my $subject = 'Hourly QC';
	my $mime_type = 'TEXT';
	my $message_body = 'WARNING! SOME OBSERVATIONS HAVE FAILED THE HOURLY QUALITY CONTROL! PLEASE DISPATCH THE SCO RAPID RESPONSE TEAM IMMEDIATELY!';
	my $attach_file = $_[0];

	my $mime_msg = MIME::Lite->new(
   	From => $from_address,
   	To   => $_[1],
  	#CC   => 'ryan_boyles@ncsu.edu,aaron_sims@ncsu.edu',
   	Subject => $subject,
   	Type => $mime_type,
   	Data => $message_body
   	)
   	or die "Error creating MIME body \n";

	$mime_msg->attach(
   	 Type  => 'TEXT',
    	Path  => $attach_file,
    	Filename => 'qc_email.txt'
    	)
    	or die "Error attaching file\n";
	
	$mime_msg->send;
}

1;

