#!/usr/bin/perl
use Getopt::Long qw (GetOptions);
use POSIX qw/ceil/;
my $cluster="vstor001";
GetOptions('c=s'=> \$cluster, 'h'=> \$help) or die "Usege: $0 --help";
if ($help eq "1")
{
    printf "--c= <vstorage cluster name>\n";
    exit 0;
}

print "Start...\n";
my $proc=25;
my @ssd=();
my @hdd=();
my %disks=();
my $ssd_count=0;
my $hdd_count=0;
@df_stor=`df|grep /vstorage`;
foreach $df (@df_stor)
{
	chomp($df);
	
	$ssd_=`echo "$df"|grep ssd|awk '{print \$1}'`;
	chomp($ssd_);
	if($ssd_ ne "")
	{	
		$disks{$ssd_}{'type'}='ssd';
		
		$ssd_size=`echo "$df"|grep $ssd_|awk '{print \$2}'`;
	    chomp($ssd_size);
		$disks{$ssd_}{'size'}=$ssd_size;
		
		$ssd_path=`echo "$df"|grep $ssd_|awk '{print \$NF}'`;
	    chomp($ssd_path);
		$disks{$ssd_}{'path'}=$ssd_path;
		$ssd_count++;
	}
	
	$hdd_=`echo "$df"|grep hdd|awk '{print \$1}'`;
    chomp($hdd_);
	if($hdd_ ne "")
	{
		$disks{$hdd_}{'type'}='hdd';
		
		$hdd_size=`echo "$df"|grep $hdd_|awk '{print \$2}'`;
	    chomp($hdd_size);
		$disks{$hdd_}{'size'}=$hdd_size;
		
		$hdd_path=`echo "$df"|grep $hdd_|awk '{print \$NF}'`;
	    chomp($hdd_path);
		$disks{$hdd_}{'path'}=$hdd_path;
		$hdd_count++;
	}
}
if( $ssd_count eq "0" || $hdd_count eq "0")
{
	printf "SSD count = 0 || HDD count = 0\n";
 	exit 1;	
}

$tcount_=0;

my $filename='/root/cs-jrnl-generate.sh';

open(my $fh,'>', $filename) or die "-|Cannot open file";

foreach my $key (keys %disks)
{
	if ( $disks{$key}{'type'} eq "ssd" )
	{
			printf "int=%s\n",int($hdd_count/$ssd_count);
			if (int($hdd_count/$ssd_count) ne 1 )
			{
				$tmp_count=ceil($hdd_count/$ssd_count);
			}
			else
			{
				$tmp_count=$hdd_count;
			}
			printf "ssd=%s hdd=%s /=%s\n",$ssd_count,$hdd_count,$tmp_count;
			$size_20=$disks{$key}{'size'}-$disks{$key}{'size'}/5;
			foreach my $k (keys %disks)
			{
				if ( $disks{$k}{'type'} eq "hdd" )
				{						
		 			printf "vstorage -c %s make-cs -r %s/cs -j  %s/%s-jrnl -s %i\n",$cluster,$disks{$k}{'path'}, $disks{$key}{'path'},$k,$size_20/$tmp_count;
		 			$str="vstorage -c ".$cluster." make-cs -r ".$disks{$k}{'path'}."/cs -j  ".$disks{$key}{'path'}."-".$k."-jrnl -s ".int($size_20/$tmp_count)."\n";
		 			print $fh $str;
		 			delete $disks{$k};
		 			$tcount_++;
		 			if ($tcount_ eq $tmp_count)
					{
						$tcount_=0;
						#delete $disks{$key};
						last;
					}
				}
			}
			$hdd_count=$hdd_count - $tmp_count;
	}  
}
printf "See %s\n",$filename;
close $fh;
exit 0;


















