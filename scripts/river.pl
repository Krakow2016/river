#The MIT License (MIT)
#Copyright (c) 2014 Krakow2016
#Permission is hereby granted, free of charge, to any person obtaining a copy
#of this software and associated documentation files (the "Software"), to deal
#in the Software without restriction, including without limitation the rights
#to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#copies of the Software, and to permit persons to whom the Software is
#furnished to do so, subject to the following conditions:
#The above copyright notice and this permission notice shall be included in all
#copies or substantial portions of the Software.
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#SOFTWARE.


############################USAGE#################################
#    
# perl river.pl <paper_src> <internet_src>
# 
# You should have CSV files for paper and internet version of Volunteers
# example: perl river.pl paper.csv int.csv
#
#
########################REVISION HISTORY##########################
# date                who                            description    
# 2014-11-08         pkasperczyk@gmail.com        Initial version
# 2014-11-15         pkasperczyk@gmail.com        Added mapping, corrected languages and previous_wyd
# 2014-11-27         pkasperczyk@gmail.com        Major changes
#
############################SCRIPT################################



#use strict;
use warnings;
use Text::CSV;
use JSON;
use utf8;
use Encode qw(encode_utf8);

my $PAPER_SRC = $ARGV[0];
my $INTERNET_SRC =$ARGV[1];
my $EMPTY_STRING = "";
my $csv = Text::CSV->new ({
    binary => 1,
    auto_diag => 1,
    sep_char => ','
});
my $csv_file_handle;

# Quotes -- windows or linux
my $osname = $^O;
my $es_inner_quote_win = "\"";
my $es_outer_quote_win = "\"";
my $es_inner_quote_linux = "";
my $es_outer_quote_linux = "\'";
my $es_inner_quote;
my $es_outer_quote;
if ($osname eq 'MSWin32')
{
    $es_inner_quote = $es_inner_quote_win;
    $es_outer_quote = $es_outer_quote_win;
}
else
{
    $es_inner_quote = $es_inner_quote_linux;
    $es_outer_quote = $es_outer_quote_linux;
}

# Elastic search documents
my $_index = "website";
my $_type = "person";
my $_id = 0;

# 
# RemoveSpecialCharacters ($string)
#
sub RemoveSpecialCharacters
{
    my $string = shift;
    $string =~ s/\n/$EMPTY_STRING/g;
    $string =~ s/\"/$EMPTY_STRING/g;
    return $string;
}

#
# IndexJSON ($_id, $json);
# Indexes JSON in Elastic Search
#
sub IndexJSON
{
    my $_id = shift;
    my $es_json = shift;

    print encode_json({ create => { _id => $_id }})."\n";
    print $es_json."\n";
}

##################Subroutines for fields######################
#
# FormatCreatedDate ($field)
#
sub FormatCreatedDate
{
	my $field = shift;
	my $created_at;
	my $year;
	my $month;
	my $day;
	my $time;
	if ($field =~ /(\d+)\/(\d+)\/(\d+) (\d\d:\d\d:\d\d)/) 
	{
		my $month = $1;
		my $day = $2;
		my $year = $3;
		my $time = $4;
		
		if ($day < 10)
		{
			$day = "0$day";
		}
		if ($month < 10)
		{
			$month = "0$month";
		}
		$created_at = $es_inner_quote."$year-$month-$day $time".$es_inner_quote;
	}	
	return $created_at;
}

#
# FormatLanguageLevel ($field)
# TODO not working
sub FormatLanguageLevel
{
	my $field = shift;
	$level = encode_utf8($field);
	#print $level, "\n";
	return 2;
	if ($level =~ /ocz/)
	{
		return 2;
	}
	elsif ($level =~ /ods/)
	{
		return 4;
	}
	elsif ($level =~ /red/)
	{
		return 6;
	}
	elsif ($level =~ /aaw/)
	{
		return 8;
	}
	elsif ($level =~ /ieg/)
	{
		return 10;
	}
}

#
# CreateDepartmentsArray ($field)
#
sub CreateDepartmentsArray
{
	my $field = shift;
	$field = RemoveSpecialCharacters($field);
	my @departments = split(/,/,$field);
	
	my $i = 0;
	my $size = @departments;
	for ($i = 0; $i < $size; $i++)
	{
		@departments[$i] = $es_inner_quote.@departments[$i].$es_inner_quote;
	}
	
	return @departments
	
}

#
# FormatConsent ($field)
#
sub FormatConsent
{
	my $field = shift;
	my $consent = substr($field,0,3);
	if ($consent=~/Tak/)
	{
		return "true";
	}
	else
	{
		return "false";
	}
}

#
# CreateJSONFromPaper ($fields)
#
sub CreateJSONFromPaper
{
    my $fields = shift;
	my $perl_scalar =
	{
		first_name => $es_inner_quote.RemoveSpecialCharacters($fields->[1]).$es_inner_quote,
		last_name => $es_inner_quote.RemoveSpecialCharacters($fields->[2]).$es_inner_quote,
		email => $es_inner_quote.RemoveSpecialCharacters($fields->[4]).$es_inner_quote,
		mobile => $es_inner_quote.RemoveSpecialCharacters($fields->[3]).$es_inner_quote,
		address2 => $es_inner_quote.RemoveSpecialCharacters($fields->[5]).$es_inner_quote,
		experience => $es_inner_quote.RemoveSpecialCharacters($fields->[6]).$es_inner_quote,
	    interests =>$es_inner_quote.RemoveSpecialCharacters($fields->[7]).$es_inner_quote,
		experience => $es_inner_quote.RemoveSpecialCharacters($fields->[6]).$es_inner_quote,
		extra => $es_inner_quote.RemoveSpecialCharacters($fields->[9]).$es_inner_quote
	};
	my $json = encode_json $perl_scalar;
	return $json
}

#
# CreateJSONFromInternet ($fields)
#
sub CreateJSONFromInternet
{
    my $fields = shift;
	my @departments = CreateDepartmentsArray($fields->[22]);
	my $perl_scalar =
	{
		created_at => FormatCreatedDate($fields->[0]),
		first_name => $es_inner_quote.RemoveSpecialCharacters($fields->[1]).$es_inner_quote,
		last_name => $es_inner_quote.RemoveSpecialCharacters($fields->[2]).$es_inner_quote,
		email => $es_inner_quote.RemoveSpecialCharacters($fields->[3]).$es_inner_quote,
		mobile => $es_inner_quote.RemoveSpecialCharacters($fields->[4]).$es_inner_quote,
		address => $es_inner_quote.RemoveSpecialCharacters($fields->[5]).$es_inner_quote,
		address2 => $es_inner_quote.RemoveSpecialCharacters($fields->[6]).$es_inner_quote,
		parish => $es_inner_quote.RemoveSpecialCharacters($fields->[7]).$es_inner_quote,
		birth_date => $es_inner_quote.RemoveSpecialCharacters($fields->[8]).$es_inner_quote,
		education => $es_inner_quote.RemoveSpecialCharacters($fields->[9]).$es_inner_quote,
		study_field => $es_inner_quote.RemoveSpecialCharacters($fields->[10]).$es_inner_quote,
        studying_from => $es_inner_quote.RemoveSpecialCharacters($fields->[11]).$es_inner_quote,
		experience => $es_inner_quote.RemoveSpecialCharacters($fields->[12]).$es_inner_quote,
		languages => [
			{ 
				name => $es_inner_quote.RemoveSpecialCharacters($fields->[13]).$es_inner_quote,
				level => FormatLanguageLevel($fields->[14])
			},
			{ 
				name => $es_inner_quote.RemoveSpecialCharacters($fields->[15]).$es_inner_quote,
				level => FormatLanguageLevel($fields->[16])
			},
			{ 
				name => $es_inner_quote.RemoveSpecialCharacters($fields->[17]).$es_inner_quote,
				level => FormatLanguageLevel($fields->[18])
			},
			{ 
				name => $es_inner_quote.RemoveSpecialCharacters($fields->[19]).$es_inner_quote,
				level => FormatLanguageLevel($fields->[20])
			}],
			  
	    interests => $es_inner_quote.RemoveSpecialCharacters($fields->[21]).$es_inner_quote,
		departments => \@departments,
		availability => $es_inner_quote.RemoveSpecialCharacters($fields->[23]).$es_inner_quote,
		previous_wyd => {
			paris => $es_inner_quote.RemoveSpecialCharacters($fields->[25]).$es_inner_quote,
			rome => $es_inner_quote.RemoveSpecialCharacters($fields->[26]).$es_inner_quote,
			toronto => $es_inner_quote.RemoveSpecialCharacters($fields->[27]).$es_inner_quote,
			cologne => $es_inner_quote.RemoveSpecialCharacters($fields->[28]).$es_inner_quote,
			sydney => $es_inner_quote.RemoveSpecialCharacters($fields->[29]).$es_inner_quote,
			madrit => $es_inner_quote.RemoveSpecialCharacters($fields->[30]).$es_inner_quote,
			rio => $es_inner_quote.RemoveSpecialCharacters($fields->[31]).$es_inner_quote },
		consent => FormatConsent($fields->[32])
	};
	my $json = encode_json $perl_scalar;
	return $json;
}


##########################SCRIPT##############################

# Create JSONs from Paper Version

open ($csv_file_handle, '<:encoding(utf8)', $PAPER_SRC) or die "Could not open '$PAPER_SRC' $!\n";
$csv->getline( $csv_file_handle );
$_id = 0;
while (my $fields = $csv->getline( $csv_file_handle )) 
{
	my $json;
    $_id++;
	$json = CreateJSONFromPaper($fields);
	IndexJSON($_id, $json);
}
if (not $csv->eof) 
{
    $csv->error_diag();
}
close $csv_file_handle;

# Create JSONs from Internet Version

open ($csv_file_handle, '<:encoding(utf8)', $INTERNET_SRC) or die "Could not open '$INTERNET_SRC' $!\n";
$csv->getline( $csv_file_handle );
while (my $fields = $csv->getline( $csv_file_handle )) 
{
	my $json;
    $_id++;
	$json = CreateJSONFromInternet($fields);
	IndexJSON($_id, $json);
}
if (not $csv->eof) 
{
    $csv->error_diag();
}
close $csv_file_handle;
