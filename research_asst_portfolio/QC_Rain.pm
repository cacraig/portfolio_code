#!/usr/bin/perl


package QC_Rain;

####################################################################################
# 		
#		A DAILY QUALITY CONTROL FOR PRECIPITATION USING GAUGE && IMPACT SENSOR && MPE 
#
# This program performs a quality control of daily gauge precipitation totals by comparing them to 
# measurements from impact sensors. If gauge precipitation differs significantly from Impact sensor 
# measurements, it fails this quality control. The database will be updated with flags.
#
#
#
#Usage:
#perl QC.pl -rain [station] -dates YYYYMMDDhhmmss YYYYMMDDhhmmss
#
#
# @By Colin Craig 
# @Change log: (7/14/11, 10/13/11, 11/28/11, 1/6/12, 1/13/12, 1/20/12, 2/14/12, 3/2/12, 3/20/12)
#  -Removed MPE estimate gathering routine
#  -Added get_impact_data($$$) routine 
#  -Replaced MPE with Impact sensor measurements in comparison
#  -Added new MPE estimate gathering routine get_mpe_data($$$)
#  -Modified compare_precip($$$) routine to compare impact,gauge, and mpe accordingly
#  -Implemented 'Zero' Check, 'Clog' Check, and an 'Range/Difference' check.
#  -Modified compare_precip($$$) running sum to be a little more lax in definition of clog
#  -Corrected Impact precip. calculation, improved readability.
#  -Partitioned Clog Check to new subroutine
#  -Added New Flag Routines to Flag.pm to handle new flags...
#  -Modified QC.pl
#  -Fixed Null issue. Missing database table rows still a potential problem though.
#  -Re-wrote Clog Check Routine, wrote new flag procedures in Flag.pm, modded QC.pl
#  -Program wil no longer quit if database values are missing. 
#  -Wrote MPE routine to pull data in 2 month increments. This modification will allow program to run on any ammount of time. 
#  
#  -To Do: Improve comparison algorithm
#
# (Missing Data)
# Example, -20110313000000 to 20110314000000 (no values for March 13th, 2011 for any station)
#	   -MITC after December 8th 15:00.
#
#
# 
####################################################################################

use Mysql;
use LWP::Simple;
use DataExtractor;
use Flag;
use Date::Calc qw(Add_Delta_Days);
use strict;
use Utilities;


my $database_name = "xxxx";

my $user = "xxxx";
my $password = "xxxx";
my $machine = "capefear.meas.ncsu.edu";

my $db = Mysql->Connect($machine,$database_name,$user,$password) or die "\nCould not connect to database '".$database_name."' as user '".$user."' at line ".__LINE__." in 'QC.pl'\n\n";

my $impact_sum=0;
my $mpe_sum=0;
my $gauge_sum=0;
my @gauge_sum_array;
my @impact_sum_array;
my @mpe_sum_array;



#----------------------------------------------------------------------
# Runs rain QC for given stations, start times, and end times. No flagging
# is performed; only an array of failed observations is returned. Refer
# to head for information about the dates.
#
# @param_0 - array reference of stations
# @param_1 - array reference of start dates (YYYY-MM-DD)
# @param_2 - array reference of end dates (YYYY-MM-DD)
# @return    array of failed observations
#----------------------------------------------------------------------
sub run_rain_qc($$$){
	
	my @stations = @{$_[0]};
	my @start_dates = @{$_[1]};
	my @end_dates = @{$_[2]};

	my %coordinates = get_lat_lon(\@stations);
	my @failed_observations;
	
	#===========================================
	# For each station
	#===========================================
	for(my$z=0;$z<@stations;$z++){
		my $lat = $coordinates{$stations[$z]}->[1];	# get station's latitude
		my $lon = $coordinates{$stations[$z]}->[2];	# get station's longitude

		my $hour=Utilities::Time_Diff($start_dates[$z],$end_dates[$z]); ##
		my @gauge_data = get_rain_data($stations[$z],$start_dates[$z],$end_dates[$z]);	# get gauge precip. data

		my @impact_data = get_impact_data($stations[$z],$start_dates[$z],$end_dates[$z],$gauge_data[0]);

		#my @impact_data = get_impact_data($stations[$z],$start_dates[$z],$end_dates[$z]);# get impact precip. data
		my @mpe_data = get_mpe_data($lat,$lon,$start_dates[$z],$end_dates[$z]);		# get mpe precip. data
		my $fail_count=0;
		
		
		my @gauge_dates = @{$gauge_data[0]};	my @gauge_precip = @{$gauge_data[1]};	# get gauge dates and values
		my @mpe_dates = @{$mpe_data[0]};	my @mpe_precip = @{$mpe_data[1]};	# get mpe dates and values###
		my @impact_dates = @{$impact_data[0]};	my @impact_precip = @{$impact_data[1]};	# get impact dates and values
		my $gauge_index = 0;	# index for gauge values and dates
		my $impact_index = 0;	# index for impact values and dates
		my $mpe_index = 0;	# index for mpe values and dates ####
		
	
	
			print $#gauge_dates."   ".$#impact_dates."    ".$#mpe_dates;

		my @flag;	
		my @null_count=@{$impact_data[2]};
		#print "$#impact_dates   $#gauge_dates     $#mpe_dates \n";
		#Organize the arrays so that dates of available data match...	
		if($#gauge_dates<$hour or $#impact_dates<$hour or $#mpe_dates<$hour){
			my %original = ();
			my @temp = ();

			#Perform an Intersection on Gauge and Impact dates.
			map { $original{$_} = 1 } @impact_dates;
			@temp = grep { $original{$_} } @gauge_dates;

			my $e;
			my $h = int substr($start_dates[$z],11,2)+1; #extracts the first hour of QC to be performed.
			my $a=$h;
			#Add hour information to MPE dates...20120204 -> 20120204HH
			foreach $e (@mpe_dates){
				$h=$a;
				if($h<10){$h="0".$h;}
				$e=$e.$h;
				$a++;
				if($a>23){$a=0;}}
			#Perform Intersection on MPE and gauge/impact intersection.
			#@intersection contains all of the dates that both impact,gauge, and mpe contain...
			%original = ();
			my @intersection = ();

			map { $original{$_} = 1 } @temp;
			@intersection = grep { $original{$_} } @mpe_dates;

			my @new_gauge_dates;
			my @new_impact_dates;
			my @new_gauge_precip;
			my @new_impact_precip;
			my @new_mpe_dates;
			my @new_mpe_precip;
			my @new_nullcount_impact;
			my $k=0;

			#Search for data that matches by dates...
			#Put this data into temp. arrays...
			#the new arrays will contain data only for dates that all three (mpe/impact/gauge) contain. 

			for(my$i;$i<@gauge_dates;$i++){
				for(my$j;$j<@intersection;$j++){
					if($gauge_dates[$i]==$intersection[$j]){
						$new_gauge_dates[$k]=$gauge_dates[$i];
						$new_gauge_precip[$k]=$gauge_precip[$i];
						$k++;}}}
			$k=0;
			for(my$i;$i<@impact_dates;$i++){
				for(my$j;$j<@intersection;$j++){
					if($impact_dates[$i]==$intersection[$j]){
						$new_impact_dates[$k]=$impact_dates[$i];
						$new_impact_precip[$k]=$impact_precip[$i];
						$new_nullcount_impact[$k]=$null_count[$i];
						$k++;}}}
			$k=0;
			for(my$i;$i<@mpe_dates;$i++){
				for(my$j;$j<@intersection;$j++){
					if($mpe_dates[$i]==$intersection[$j]){
						$new_mpe_dates[$k]=$mpe_dates[$i];
						$new_mpe_precip[$k]=$mpe_precip[$i];
						$k++;}}}

			#makes sure dates are aligned...sometimes when there are gaps in the DB, the impact precip will be off by an hour. 
			if($#new_impact_precip != $#new_impact_dates){shift(@new_impact_precip);}	


			#Set all the original arrays equal the new temp arrays containing the correct data, aligned with dates.
			@impact_dates=@new_impact_dates;
			@impact_precip=@new_impact_precip;
			@gauge_dates=@new_impact_dates;
			@gauge_precip=@new_gauge_precip;
			@mpe_dates=@new_mpe_dates;
			@mpe_precip=@new_mpe_precip;

			
			}

			#Continue now with Precipitation QC... 


		my @temp_gauge_precip;
		my @temp_mpe_precip;
		my @temp_dates;
		#===============================================
		#Loop through each observation, and perform QC.
		#===============================================
		
		while($gauge_index < @gauge_dates  && $impact_index < @impact_dates && $mpe_index < @mpe_dates){
		#print  "$gauge_dates[$gauge_index]	 $gauge_precip[$gauge_index]	 $impact_dates[$impact_index] \n";

			if($gauge_dates[$gauge_index]==$impact_dates[$impact_index]){
		
				#===========================================
				# If the observation value is not NULL
				#===========================================
				if($null_count[$gauge_index]==60){push(@temp_gauge_precip,$gauge_precip[$gauge_index]);
								  push(@temp_mpe_precip,$mpe_precip[$gauge_index]);
								  push(@temp_dates,$gauge_dates[$gauge_index]);}
				if($gauge_precip[$gauge_index] != -99 && $null_count[$gauge_index]<9){
				
					@flag = compare_precip($gauge_precip[$gauge_index],$impact_precip[$impact_index],$mpe_precip[$mpe_index]);
					
					print " @flag	$stations[$z]	$gauge_dates[$gauge_index]	$gauge_precip[$gauge_index]	$impact_dates[$impact_index] 	$impact_precip[$impact_index]	$mpe_precip[$mpe_index]	\n";
				
					my @failed = ($flag[0],$flag[1],$stations[$z],$gauge_dates[$gauge_index]);
					if($flag[0]>0 or $flag[1]>0){
						push (@{$failed_observations[$fail_count]},@failed);
						$fail_count++;}
				}
				
				$gauge_index++;
				$impact_index++;
				$mpe_index++;###
			
			
			}
		  
		}
	my @other_failed=Precip_QC_Pre_Impact(\@temp_gauge_precip,\@temp_mpe_precip,\@temp_dates,$stations[$z]);
	push(@failed_observations,@other_failed);
	}
	
	return @failed_observations;
}

#=============================================================
#This routine handles gauge data in the absence of impact sensor data.
#Simple comparison with Gauge and MPE
# @param_0 - array reference for gauge data
# @param_1 - array reference for mpe data
# @param_2 - array reference for dates
# @param_3 - Station
#
#=============================================================
sub Precip_QC_Pre_Impact($$$){
	my @gauge = @{$_[0]};
	my @mpe = @{$_[1]};
	my @dates=@{$_[2]};
	my $station=$_[3];

	my @gauge_sum_array;
	my @mpe_sum_array;
	my @failed_observations;
	my $fail_count;
	my $gauge_flag;
	my $index;
	my $gauge_sum;
	my $mpe_sum;
	my $diff=0;
	#######
	#Will not check unless there is 15 days of past data available. 
	#Dynamically builds sums...if discontinuity occurs, it will reset the sum.
	#Once the sum array is filled (reaches 360 hours) it will sum, and perform QC
	#on Current hour, using the past 15 day sum of MPE and Gauge (Similar to Clog check routine.)
	#######

	for(my$i=0;$i<@dates;$i++){
		if($i!=0){$diff= Utilities::Time_Diff_int($dates[$i-1],$dates[$i]);}
		$index=$#dates-$i;

		#if discontinuity occurs...
		if($diff>1){
			@gauge_sum_array=();
			@mpe_sum_array=();
			push(@gauge_sum_array,$gauge[$i]);
			push(@mpe_sum_array,$mpe[$i]);
			}
		if($diff==1){
		push(@gauge_sum_array,$gauge[$i]);
		push(@mpe_sum_array,$mpe[$i]);
			if($#gauge_sum_array==360){
			$gauge_sum=0;$mpe_sum=0;
			shift(@gauge_sum_array);
			shift(@mpe_sum_array);
			($gauge_sum+=$_) for @gauge_sum_array; #sum all elements in array containing past 15 days.
			($mpe_sum+=$_) for @mpe_sum_array;
			#print "GAUGE SUM: $gauge_sum    MPE SUM: $mpe_sum\n";
			}
		}

		if($mpe_sum>1 ){ #Done to assure periods of absent precip are not flagged.
		if(($gauge_sum/$mpe_sum)<=.25 or ($gauge_sum/$mpe_sum)>=1.75){
			$gauge_flag=2;}}

		if($gauge[$i]==-99){$gauge_flag=0;} #If null.

		my @failed = ($gauge_flag,0,$station,$dates[$i]);
		if($gauge_flag>0){
			push (@{$failed_observations[$fail_count]},@failed);$fail_count++;}
		}
	
		
	return @failed_observations;

}






#########################
#Calculates 15 day sum.
#Performs Clog Check on only current hour.
#
#@param1=Stations
#@param2=Current hour being QC'd
#@param3=End Date
#returns either a 0 or a 4. 
#4 - Clog Detected
#0 - Good
#########################
sub Clog_Check($$$){
my @failed_observations;
my @stations = @{$_[0]};
my @start_dates = @{$_[1]};
my @end_dates = @{$_[2]};

my @gauge_sum_array;
my @impact_sum_array;
my @mpe_sum_array;

my $impact_sum=0;
my $mpe_sum=0;
my $gauge_sum=0;
my @failed=0;
my @failed_observations;


#####
for(my$z=0;$z<@stations;$z++){
	my $hour=Utilities::Time_Diff($start_dates[$z],$end_dates[$z]); #Number of hours to QC check.
	my $end= $end_dates[$z]; #This is the current hour being checked.
	my %coordinates = get_lat_lon(\@stations);
	my $lat = $coordinates{$stations[$z]}->[1];	# get station's latitude
	my $lon = $coordinates{$stations[$z]}->[2];	# get station's longitude'
	my $fail_count;
	my $current_hour=0;
	my $past_gauge_index=359; #Number of hours of past data 15 days [0-359] 
	my $past_impact_index=359;

my $start= Utilities::Day_Subtract($start_dates[$z]); #This takes the date and subtracts 15 days.

		my @gauge_data=get_rain_data($stations[$z],$start,$end);
		my @impact_data = get_impact_data($stations[$z],$start,$end,$gauge_data[0]);
		my @mpe_data =get_mpe_data($lat,$lon,$start,$end);
		my @gauge_dates = @{$gauge_data[0]};	my @gauge_precip = @{$gauge_data[1]};	# get gauge dates and values
		my @mpe_dates = @{$mpe_data[0]};	my @mpe_precip = @{$mpe_data[1]};	# get mpe dates and values###
		my @impact_dates = @{$impact_data[0]};	my @impact_precip = @{$impact_data[1]};	# get impact dates and values
		my @null_count=@{$impact_data[2]};
		

#Organize the arrays so that dates of available data match...
if(($#gauge_precip-$hour)<$past_gauge_index or ($#impact_precip-$hour)<$past_impact_index){ #there is some missing data...


$past_impact_index =$#gauge_precip-$hour; #There is less than 15 days worth of aval. data...
$past_gauge_index =$#impact_precip-$hour;
	
#Perform an Intersection on Gauge and Impact dates.


my %original = ();
my @temp = ();

map { $original{$_} = 1 } @impact_dates;
@temp = grep { $original{$_} } @gauge_dates;

my $e;
my $h = int substr($start_dates[$z],11,2)+1;
my $a=$h;

#Add hour information to MPE dates...
foreach $e (@mpe_dates){
	$h=$a;
	if($h<10){$h="0".$h;}
	$e=$e.$h;
	$a++;
	if($a>23){$a=0;}}

#Add hour information to MPE dates...20120204 -> 20120204HH
%original = ();
my @intersection = ();

map { $original{$_} = 1 } @temp;
@intersection = grep { $original{$_} } @mpe_dates;

#Perform Intersection on MPE and gauge/impact intersection.
#@intersection contains all of the dates that both impact,gauge, and mpe contain...

my @new_gauge_dates;
my @new_impact_dates;
my @new_gauge_precip;
my @new_impact_precip;
my @new_mpe_dates;
my @new_mpe_precip;
my @new_nullcount_impact;
my $k=0;

#Search for data that matches by dates...
#Put this data into temp. arrays...
#the new arrays will contain data only for dates that all three (mpe/impact/gauge) contain.
for(my$i;$i<@gauge_dates;$i++){
	for(my$j;$j<@intersection;$j++){
		if($gauge_dates[$i]==$intersection[$j]){
			$new_gauge_dates[$k]=$gauge_dates[$i];
			$new_gauge_precip[$k]=$gauge_precip[$i];
			$k++;}}}
$k=0;
for(my$i;$i<@impact_dates;$i++){
	for(my$j;$j<@intersection;$j++){
		if($impact_dates[$i]==$intersection[$j]){
			$new_impact_dates[$k]=$impact_dates[$i];
			$new_impact_precip[$k]=$impact_precip[$i];
			$new_nullcount_impact[$k]=$null_count[$i];
			$k++;}}}
$k=0;
for(my$i;$i<@mpe_dates;$i++){
	for(my$j;$j<@intersection;$j++){
		if($mpe_dates[$i]==$intersection[$j]){
			$new_mpe_dates[$k]=$mpe_dates[$i];
			$new_mpe_precip[$k]=$mpe_precip[$i];
			$k++;}}}

#Fixes impact precip if off.
if($#new_impact_precip != $#new_impact_dates){shift(@new_impact_precip);}
#Set all the original arrays equal the new temp arrays containing the correct data, aligned with dates.

@impact_dates=@new_impact_dates;
@impact_precip=@new_impact_precip;
@gauge_dates=@new_impact_dates;
@gauge_precip=@new_gauge_precip;
@mpe_dates=@new_mpe_dates;
@mpe_precip=@new_mpe_precip;
@null_count=@new_nullcount_impact;

#Reset index. 
$past_impact_index =$#gauge_precip-$hour; 
$past_gauge_index =$#impact_precip-$hour;
			
#for($k=0;$k<@impact_dates;$k++){
#print "$stations[$k]	$gauge_dates[$k]	$gauge_precip[$k]	$impact_dates[$k]    	$impact_precip[$k]	$mpe_precip[$k] \n";}

}

#===================================================
#Clog Check Algorithm. Loops through each QC hour. 
#===================================================

while($current_hour<$hour){
	#If the hour ob for gauge or impact is null...skip...
	if($null_count[$past_impact_index+$current_hour]>9 or $gauge_precip[$past_gauge_index+$current_hour]==-99){goto CON;}

	#Check Past 15 days for 85% obs. 
	# 15% of 15 days is 306 hours. If there is less than 306 hours of past data skip this QC hour. 
	if(($past_impact_index+$current_hour)<306 or ($past_gauge_index+$current_hour)<306){goto CON;}

	$gauge_sum=0;
	$mpe_sum=0;
	$impact_sum=0;
	my $impact_flag=0;
	my $gauge_flag=0;
	my @flag; 

	if($current_hour>0){
		shift(@gauge_sum_array);
		shift(@impact_sum_array);
		shift(@mpe_sum_array);
		push(@gauge_sum_array,$gauge_precip[$past_gauge_index+$current_hour]);
		if($impact_precip[$past_impact_index+$current_hour]>=0){push(@impact_sum_array,$impact_precip[359+$current_hour]);}
		push(@mpe_sum_array,$mpe_precip[$past_gauge_index+$current_hour]);}
		

	if($current_hour==0){
	for(my$i;$i<=$past_gauge_index;$i++){
		if($impact_precip[$i]<0){$impact_precip[$i]=0;} #Keeps negative faulty values from messing up routine. 
			push(@gauge_sum_array,$gauge_precip[$i]);
			push(@impact_sum_array,$impact_precip[$i]);
			push(@mpe_sum_array,$mpe_precip[$i]);}}

	($gauge_sum+=$_) for @gauge_sum_array; #sum all elements in array containing past 15 days.
	($impact_sum+=$_) for @impact_sum_array;
	($mpe_sum+=$_) for @mpe_sum_array;


	# 'Clog check' for Gauge, based on impact and MPE.
	# (1) Check ratio of (15 day sum) Gauge and Impact sensor. If it is small, then proceed.
	# (2) Check ratio of (15 day sum) MPE and Impact/gauge sensors. If it is between .5 and 1.5, then proceed.
	#	->This ensures that there is atleast decent basis that the sensor compared to MPE is reliable enough to deem 		   		#	   the other sensor as clogged.
	#		*Note: Second opinion needed*
	#
	# (3) Flag the gauge, because it has likely gone bad.

	if($impact_sum>.2 ){ #Done to assure periods of absent precip are not flagged.
		if(($gauge_sum/$impact_sum)<=.25 or ($gauge_sum/$impact_sum)>=1.75){
			if(($mpe_sum/$impact_sum)>=.5 && ($mpe_sum/$impact_sum)<= 1.5){
				$gauge_flag=4;}}}

	# 'Clog check' for Impact sensor, based on gauge and MPE.
	if($gauge_sum>.2 ){
		if(($impact_sum/$gauge_sum)<=.25 or ($impact_sum/$gauge_sum)>=1.75){
			if(($mpe_sum/$gauge_sum)>=.5 && ($mpe_sum/$gauge_sum)<= 1.5){
				$impact_flag=4;}}}

	#This is an arbitrary catch to keep from 'Clog' Flagging data that shouldn't be flagged.
	#IF a sensor is flagged as 'clogged' and it is reporting a positive value, then it is not clogged.

	#The index+current_hour ob is the current hour observation (position 359+current hour) 		
	#0-358 are the previous 15 days.  if all data is availiable.
	#if($gauge_flag ==4 && $gauge_precip[$past_gauge_index+$current_hour]>0){$gauge_flag=0;}
	#if($impact_flag ==4 && $impact_precip[$past_impact_index+$current_hour]>0){$impact_flag=0;} 

	#If the Gauge and the MPE, or the Impact and MPE are 0...don't flag that hour. 
	#
	if(($gauge_precip[$past_gauge_index+$current_hour]==0 && $mpe_precip[$past_gauge_index+$current_hour]==0) or ($impact_precip[$past_impact_index+$current_hour]==0 && $mpe_precip[$past_gauge_index+$current_hour]==0)){
		$gauge_flag=0;$impact_flag=0;}

	@flag=($gauge_flag,$impact_flag);
	if($flag[0]>=0 or $flag[1]>=0){
		@failed = ($flag[0],$flag[1],$stations[$z],$gauge_dates[$past_gauge_index+$current_hour]);
		push (@{$failed_observations[$fail_count]},@failed);
		$fail_count++;}
	
	use Data::Dumper;
	print Dumper(@flag)."\n";
	
	CON: $current_hour++; }} 
return @failed_observations;
}

#----------------------------------------------------------------------
# Compares gauge, impact sensor, and mpe precipitation measurements. 
# Preforms several checks, assigning various flags to the gauge, and/or impact sensor measurments. 
# 
#
# 'I' -> One of the sensors is suspect. TBD which...
# -1 -> Particular sensor possibly clogged. 
#  0  -> Okay.
#  1  -> Suspect data.
# 
#
# @param_0 - gauge precipitation measurement
# @param_1 - impact sensor precipitation measurement
# @return  - flags (Gauge Flag, Impact Flag)
#----------------------------------------------------------------------

sub compare_precip($$$){

	my $gauge_precip = $_[0];
	my $impact_precip = $_[1];
	my $mpe_precip = $_[2];

	my $gauge_flag = 0;
	my $impact_flag = 0;


	$gauge_sum=0; 
	$impact_sum=0; 
	$mpe_sum=0;

	my @flags;

	my $diff_impact_gauge = abs($gauge_precip-$impact_precip);
	my $diff_mpe_impact = abs($mpe_precip - $gauge_precip);
	my $diff_mpe_gauge = abs($mpe_precip - $impact_precip);



	#When Impact sensor is faulty, will report negative values. 
	#In order maintain reasonable 15 day summation...if the impact sensor reads a negative value,
	#round the impact sensor value off to 0. 
	#
	#For example, if the impact sensor reads -67 inches of precipitation, this will throw the 15 day running sum off
	#by a large margin, which will in turn cause the 'Clog' check to hit until this value is pushed off the sum 'stack'
	#(ie. the next 359 hours)
	#By removing these clearly faulty values, consistancy can be maintained.

	if($impact_precip<0){$impact_precip=0;$impact_flag=4;}


	#If the gauge precipitation > .05, and Impact/Gauge <= .5 or ($impact_precip/$gauge_precip)>= 1.5
	#Flag both the gauge and the impact sensor with an Intersensor 'I' Flag,
	#Then compare to MPE.
	#
	#If the difference between MPE and impact is >= .25 inches, and difference between MPE and gauge <= .5 inches,
	#Flag Gauge, remove flag from impact.
	#
	#If the difference between MPE and gauge is >= .25 and difference between MPE and impact sensor is <=.5, 
	#Flag impact, remove flag from gauge
	#
	#

	if($gauge_precip>.05){
	if((($impact_precip/$gauge_precip)<=.5) or (($impact_precip/$gauge_precip)>= 1.5)){

		if($gauge_flag==4 or $impact_flag==4){
			@flags = ($gauge_flag,$impact_flag);
			return @flags;} #Allow worst flag to take precedence

		$gauge_flag = 1;
		$impact_flag = 1;
		
			if(($diff_impact_gauge>=.25) && ($diff_mpe_gauge<=.5)){
				$impact_flag = 1;
				$gauge_flag = 2;
				
				}
			if(($diff_impact_gauge>=.25) && ($diff_mpe_impact<=.5)){
				$gauge_flag=1;
				$impact_flag=2;
				}
						

		}	}


	if($impact_precip>.05 ){
	if((($gauge_precip/$impact_precip)<=.5) or (($gauge_precip/$impact_precip)>= 1.5)){

		if($gauge_flag==4 or $impact_flag==4){
			@flags = ($gauge_flag,$impact_flag);
			return @flags;} #Allow worst flag to take precedence

		$gauge_flag = 1;
		$impact_flag = 1;
			if(($diff_impact_gauge>=.25) && ($diff_mpe_gauge<=.5)){
				$impact_flag = 1;
				$gauge_flag = 2;
				
				}
			if(($diff_impact_gauge>=.25) && ($diff_mpe_impact<=.5)){
				$gauge_flag=1;
				$impact_flag=2;
				}
						

		}	}



	#If mpe>.5, gauge>0, gauge/mpe ~= 1, and impact is 0. Then impact is possibly bad.
	
	if(($mpe_precip>.5)&&($impact_precip==0)&&($gauge_precip>0)&&( (($gauge_precip/$mpe_precip)>=.9) && (($gauge_precip/$mpe_precip)<= 1.1) ) ){
		
		$impact_flag = 4;

	}
	#If mpe>.5, impact>0, impact/mpe ~= 1, and gauge is 0. Then gauge is possibly bad.

	if(($mpe_precip>.5)&&($gauge_precip==0)&&($impact_precip>0)&&( (($impact_precip/$mpe_precip)>=.9) && (($impact_precip/$mpe_precip)<= 1.1) ) ){

		$gauge_flag = 4;

	}



	@flags = ($gauge_flag,$impact_flag);

	#Zero Check
	if($gauge_precip==0 && $impact_precip==0){ 
		$gauge_flag = 0;
		$impact_flag = 0;
		@flags = ($gauge_flag,$impact_flag);
		}

	return @flags;
}

#----------------------------------------------------------------------
#Get gauge data
#
# @param_0 - station
# @param_1 - start date (YYYY-MM-DD)
# @param_2 - end date (YYYY-MM-DD)
# @return 
#----------------------------------------------------------------------
sub get_rain_data($$$){

	my $station = $_[0];
	my $start_date = $_[1];
	my $end_date = $_[2];
	#print $start_date."  ".$end_date;
	
	

	my @precip_data;
	my @dates;
	
	my $query = "SELECT station,DATE_FORMAT(ob,'%Y%m%d%H'),precip FROM hourly WHERE station = '$station' AND ob > '$start_date' AND ob <= '$end_date' AND obtype = 'H' ";
	my $result = $db->Query($query);
	my $row_count = $result->numrows;
	
	
	my @row;
	
	for(my$i=0;$i<$row_count;$i++){
	
		@row = $result->FetchRow;
		
		$dates[$i] =  int $row[1];
		$dates[$i] = (int $dates[$i]); 
		$precip_data[$i] = $row[2];
		#if(($row[2] eq undef)&&($row[2]!=0)){$precip_data[$i]=-99;}
		
	}
	
	my @output = (\@dates,\@precip_data);
	
	return @output;
}


##################################
#Retrieves impact sensor data
#
###################################

sub get_impact_data($$$$){


	my @impact_output;
	
	my $station = $_[0];
	my $start_date = $_[1];
	my $end_date = $_[2];
	my @G_dates=@{$_[3]};
	
	my @precip_data;
	my @dates;
	
	my $query = "SELECT station,DATE_FORMAT(ob,'%Y%m%d%H%i'),IFNULL(precipimpact1,'n') FROM hourly WHERE station = '$station' AND ob >= '$start_date' AND ob < '$end_date' AND obtype = 'O'  ";

	my $result = $db->Query($query);
	my $row_count = $result->numrows;
	my $m;

	my @row;
	my @minute_sums;
	my @newdates;
	my $k=0;
	my $count=0;
	my @null_count;

	@row = $result->FetchRow; #Removes Header Row. 

	for(my$i=0;$i<$row_count;$i++){
		
		$m=int substr($row[1],10,2);
		#print $m."\n";
		$dates[$i] = int substr($row[1],0,10);
		$precip_data[$i] = $row[2];
		if($row[2]eq 'n'){$precip_data[$i]=0;$null_count[$k]++;}
		$newdates[$k]=$dates[$i];
		@row = $result->FetchRow;
		$minute_sums[$k]=$minute_sums[$k]+$precip_data[$i];
		if($m==59){$k++;$newdates[$k]=$dates[$i];}
		}
	#use Time::Local;
	
	#my $dt1;
	#my $dt2;

	for(my$j=0;$j<@newdates;$j++){
		
		$newdates[$j]=Utilities::hour_addition($newdates[$j]);
		if($newdates[$j] != $G_dates[$j]){$newdates[$j]=Utilities::hour_addition($newdates[$j]);}
		print "$G_dates[$j]   $newdates[$j] \n";
		}

	my @impact_output = (\@newdates,\@minute_sums,\@null_count);

	return @impact_output;
	
}

################################################
#Gets MPE data
#################################################

sub get_mpe_data($$$$){
	my $SD;
	my $lat = $_[0];
	my $lon = $_[1];
	my $start_date = $_[2]; #YYYY-MM-DD HH:MM:SS
	my $end_date = $_[3];
	my @precip;		# record for precipitation
	my @dates;		# record for dates
	my @temp_Dates=();
	my @temp_Precip=();
	$start_date= Utilities::hour_addition_string($start_date);
	$end_date=Utilities::hour_addition_string($end_date);
	my $ED=$start_date;
	
	my $Length_of_Period=Utilities::Time_Diff($start_date,$end_date);
	while($Length_of_Period>1500){
		$ED=Utilities::M2_Add($ED);
		$Length_of_Period=$Length_of_Period-Utilities::Time_Diff($start_date,$ED);
		my $url = "http://www.nc-climate.ncsu.edu/mpe/get_mpewebpage.php?lat=$lat&lon=$lon&startdate=$start_date&enddate=$ED&stage=4&period=01";
		my $content = get $url;
		my @tokenized_content = split(/\n/,$content);
		my @tokenized_line;
		@temp_Dates=();
		@temp_Precip=();
		for(my$i=0;$i<@tokenized_content;$i++){
			
			@tokenized_line = split(/\|/,$tokenized_content[$i]);
			$tokenized_line[1] =~ s/\t |  //g;
			$temp_Dates[$i] = $tokenized_line[1];
			$temp_Dates[$i] = substr($temp_Dates[$i],0,10);
			$temp_Dates[$i] =~ s/-|:| //ig;
			$temp_Dates[$i] = int $temp_Dates[$i];
			if($tokenized_line[0]!=9999){ $temp_Precip[$i] = $tokenized_line[0];}
				else { $temp_Precip[$i] = 0;}}
		push(@dates,@temp_Dates);
		push(@precip,@temp_Precip);
		$start_date= Utilities::hour_addition_string($ED);
		}
		
	
	#print "$start_date     $end_date    $Length_of_Period  Precip: $#precip\n";

	my $url = "http://www.nc-climate.ncsu.edu/mpe/get_mpewebpage.php?lat=$lat&lon=$lon&startdate=$start_date&enddate=$end_date&stage=4&period=01";
	my $content = get $url;

	
	my @tokenized_content = split(/\n/,$content);
	my @tokenized_line;
	

	@temp_Dates=();
	@temp_Precip=();
	#
	# Extract dates and precipitation
	#
	for(my$i=0;$i<@tokenized_content;$i++){
		@tokenized_line = split(/\|/,$tokenized_content[$i]);
		$tokenized_line[1] =~ s/\t |  //g;
		$temp_Dates[$i] = $tokenized_line[1];
		$temp_Dates[$i] = substr($temp_Dates[$i],0,10);
		$temp_Dates[$i] =~ s/-|:| //ig;
		$temp_Dates[$i] = int $temp_Dates[$i];
		if($tokenized_line[0]!=9999){ $temp_Precip[$i] = $tokenized_line[0];}
			else { $temp_Precip[$i] = 0;}}
	
	push(@dates,@temp_Dates);
	push(@precip,@temp_Precip);
	
	my @output = (\@dates,\@precip);
	return @output;
}
#########################
#Gets latitude and Longitude for location.
#
#########################
sub get_lat_lon($){

	my @stations = @{$_[0]};
	
	my %output;
	
	my $station_string;
	
	#
	# Construct query to get coordinates
	#
	for(my$i=1;$i<@stations;$i++){ $station_string = "OR station = '$stations[$i]' $station_string";}
	my $query = "SELECT station,lat,lon FROM statmeta WHERE station = '$stations[0]' $station_string";
	
	#
	# Get results
	#
	my $result = $db->Query($query);
	my $result_count = $result->numrows;
	
	#
	# Store data in a hash
	#
	for(my$i=0;$i<$result_count;$i++){
		
		my @row = $result->FetchRow;
		
		$output{$row[0]} = \@row;
	}
	
	return %output;
}



###############################
#Retrieves Station Data
#
# 
###############################
sub get_station_data(){

	my $query = "SELECT stat.station,last_qc_precip FROM statmeta AS stat, parameta_hourly AS para WHERE para.precip IS NOT NULL AND stat.has_hourly = 1 AND stat.type != 'BUOY' AND stat.type != 'NOS' AND stat.type != 'CMAN' AND stat.type != 'USCRN' GROUP BY stat.station";
	#my $query = "SELECT station,last_qc_precip FROM statmeta WHERE station = 'GMCR'";
	my $result = $db->Query($query);
	my $result_count = $result->numrows;
	my @row;
	
	my @stations;
	my @dates;
	
	for(my$i=0;$i<$result_count;$i++){
	
		@row = $result->FetchRow;
	
		$stations[$i] = $row[0];
		$dates[$i] = $row[1];
	}
	
	my @output = (\@stations,\@dates);
	
	return @output;
}


#----------------------------------------------------------------------
# Given a single station, start date, and end date, inserts flags into
# the database. Refer to head for information about dates.
#----------------------------------------------------------------------
sub flag_precip($$$){
	
	my $station = $_[0];	# single station
	my $start_date = $_[1];	# start date (YYYY-MM-DD)
	my $end_date = $_[2];	# end date (YYYY-MM-DD)
	my $flag = $_[3];	# flag to insert (.e.g. R0, R1, etc...)
	
	my @new_date = Add_Delta_Days(substr($start_date,0,4),substr($start_date,5,2),substr($start_date,8,2),-1);
	
	if($new_date[1]<10){ $new_date[1] = "0".$new_date[1]};
	if($new_date[2]<10){ $new_date[2] = "0".$new_date[2]};
	
	$start_date = "$new_date[0]-$new_date[1]-$new_date[2]";
	
	my $query = "UPDATE hourly SET precipflag = IF(precipflag IS NULL,'$flag',IF(precipflag REGEXP 'R',
	REPLACE(REPLACE(REPLACE(REPLACE(precipflag,'R0','$flag'),'R1','$flag'),'R2','$flag'),'R3','$flag'),CONCAT(precipflag,'$flag')))
	WHERE station = '$station' AND precip IS NOT NULL AND (precipflag NOT REGEXP '$flag' OR precipflag IS NULL)
	AND ob > '$start_date 07:00:00' AND ob <= '$end_date 07:00:00'";
	
	$db->Query($query)
}1;

