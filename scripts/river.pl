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
# perl river.pl <internet_src>
# 
# You should have CSV files for internet version of Volunteers
# example: perl river.pl int.csv
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
use Date::Parse;
use DateTime;
use Time::Piece;

my $INTERNET_SRC =$ARGV[0];
my $EMPTY_STRING = "";
my $csv = Text::CSV->new ({
    binary => 1,
    auto_diag => 1,
    sep_char => ','
});
my $csv_file_handle;

# Quotes -- windows or linux
my $osname = $^O;
my $es_inner_quote_win = "";
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
# IndexJSON ($_id, $json);
# Indexes JSON in Elastic Search
#
sub IndexJSON
{
    my $_id = shift;
    my $es_json = shift;

    print encode_json({ index => { _id => $INTERNET_SRC.":".$_id }})."\n";
    print $es_json."\n";
}

#
# FormatLanguageLevel ($field)
# not the best, but working
sub FormatLanguageLevel
{
    my $field = shift;
    my $level = substr(encode_utf8($field), 0 , 5);
    if ($level =~ /Pocz/)
    {
        return 2;
    }
    elsif ($level =~ /Pods/)
    {
        return 4;
    }
    elsif ($level =~ /red/)
    {
        return 6;
    }
    elsif ($level =~ /Zaaw/)
    {
        return 8;
    }
    elsif ($level =~ /Bieg/)
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
    my @departments = split(/,/,$field);
    
    my $i = 0;
    my $size = @departments;
    for ($i = 0; $i < $size; $i++)
    {
        @departments[$i] = $es_inner_quote.@departments[$i].$es_inner_quote;
    }
    
    return @departments;
    
}

#
# CreatePreviousWyd ($fields)
#
sub CreatePreviousWyd
{
    my $fields = shift;
    my $previous_wyd;
    my @cities = ("paris", "rome", "toronto", "cologne", "sydney", "madrit", "rio");
    my $size_cities = @cities;
    my $index = 0;
    for ($index = 0; $index < $size_cities; $index++)
    {
        if ( length($fields->[25+$index]) ) 
        {
            $previous_wyd->{@cities[$index]} = $es_inner_quote.$fields->[25+$index].$es_inner_quote;
        }
    }
    return $previous_wyd;    
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
        return JSON::true;
    }
    else
    {
        return JSON::false;
    }
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
        created_at => DateTime->from_epoch(epoch => str2time($fields->[0]))->datetime,
        first_name => $es_inner_quote.$fields->[1].$es_inner_quote,
        last_name => $es_inner_quote.$fields->[2].$es_inner_quote,
        email => $es_inner_quote.$fields->[3].$es_inner_quote,
        mobile => $es_inner_quote.$fields->[4].$es_inner_quote,
        address => $es_inner_quote.$fields->[5].$es_inner_quote,
        address2 => $es_inner_quote.$fields->[6].$es_inner_quote,
        parish => $es_inner_quote.$fields->[7].$es_inner_quote,
        birth_date => DateTime->from_epoch(epoch => str2time($fields->[8]))->ymd('-'),
        education => $es_inner_quote.$fields->[9].$es_inner_quote,
        study_field => $es_inner_quote.$fields->[10]."; Rok studiów: ".$fields->[11].$es_inner_quote,
        experience => $es_inner_quote.$fields->[12].$es_inner_quote,
        interests => $es_inner_quote.$fields->[21].$es_inner_quote,
        departments => \@departments,
        availability => $es_inner_quote.$fields->[23].$es_inner_quote,
        consent => FormatConsent($fields->[32])
    };
    
	#languages
	my $index_languages = 0;
	for ($index_languages = 0; $index_languages < 8; $index_languages=$index_languages+2)
    {
        if ( length($fields->[13+$index_languages]) ) 
        {
			my $name;
			my $text1 = $fields->[13+$index_languages];
			my $text2 = " ";
			$text1 =~ /(.*)( )(.*)$/;
			$text2 = $3;
			if (defined($text2) and length($text2) > 0)
			{
				$name = $text2;
			}
			else
			{
				$name = $fields->[13+$index_languages];
			}
            $perl_scalar->{languages}->{$name}->{level}= FormatLanguageLevel($fields->[13+$index_languages+1]);
        }
    }
	
    my $previous_wyd = CreatePreviousWyd($fields);
    my $size_previous_wyd = keys %$previous_wyd;
    if ($size_previous_wyd)
    {
        $perl_scalar->{previous_wyd} = $previous_wyd;
    }
        
    my $json = encode_json $perl_scalar;
    return $json;
}


##########################SCRIPT##############################

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
