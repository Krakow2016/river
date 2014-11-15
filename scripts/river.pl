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
#
############################SCRIPT################################



use strict;
use warnings;
use Text::CSV;

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
my $es_inner_quote_win = "\"\"";
my $es_outer_quote_win = "\"";
my $es_inner_quote_linux = "\"";
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

my $created_at;
my $first_name;
my $last_name;
my $email;
my $mobile;
my $address;
my $address2;
my $parish;
my $birth_date;
my $education;
my $study_field;
my $studying_from;
my $experience;
my $languages;
my $interests;
my $departments;
my $availability;
my $previous_wyd;
my $consent;
my $extra;


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
# ReadPaperLine ($fields);
#
sub ReadPaperSrcLine
{
    my $fields = shift;
    $created_at = $EMPTY_STRING;
    $first_name = RemoveSpecialCharacters($fields->[1]);
    $last_name = RemoveSpecialCharacters($fields->[2]);
    $email = RemoveSpecialCharacters($fields->[4]);
    $mobile = RemoveSpecialCharacters($fields->[3]);
    $address = $EMPTY_STRING;
    $address2 = RemoveSpecialCharacters($fields->[5]);
    $parish = $EMPTY_STRING;
    $birth_date = "2000-01-01";
    $education = $EMPTY_STRING;
    $study_field = $EMPTY_STRING;
    $studying_from = $EMPTY_STRING;
    $experience = RemoveSpecialCharacters($fields->[6]);
    
    $languages = "[{";
    $languages .= $es_inner_quote."name".$es_inner_quote.": ".$es_inner_quote.$EMPTY_STRING.$es_inner_quote.", "; 
    $languages .= $es_inner_quote."level".$es_inner_quote.": ".$es_inner_quote.$EMPTY_STRING.$es_inner_quote."}, {"; 
    $languages .= $es_inner_quote."name".$es_inner_quote.": ".$es_inner_quote.$EMPTY_STRING.$es_inner_quote.", "; 
    $languages .= $es_inner_quote."level".$es_inner_quote.": ".$es_inner_quote.$EMPTY_STRING.$es_inner_quote."}, {";
    $languages .= $es_inner_quote."name".$es_inner_quote.": ".$es_inner_quote.$EMPTY_STRING.$es_inner_quote.", "; 
    $languages .= $es_inner_quote."level".$es_inner_quote.": ".$es_inner_quote.$EMPTY_STRING.$es_inner_quote."}, {";
    $languages .= $es_inner_quote."name".$es_inner_quote.": ".$es_inner_quote.$EMPTY_STRING.$es_inner_quote.", "; 
    $languages .= $es_inner_quote."level".$es_inner_quote.": ".$es_inner_quote.$EMPTY_STRING.$es_inner_quote."}]";
    
    $interests = RemoveSpecialCharacters($fields->[7]);
    $departments = $EMPTY_STRING;
    $availability = $EMPTY_STRING;

    $previous_wyd = "{";
    $previous_wyd .= $es_inner_quote."attendance".$es_inner_quote.": ".$es_inner_quote.$EMPTY_STRING.$es_inner_quote.", "; 
    $previous_wyd .= $es_inner_quote."paris".$es_inner_quote.": ".$es_inner_quote.$EMPTY_STRING.$es_inner_quote.", "; 
    $previous_wyd .= $es_inner_quote."rome".$es_inner_quote.": ".$es_inner_quote.$EMPTY_STRING.$es_inner_quote.", "; 
    $previous_wyd .= $es_inner_quote."toronto".$es_inner_quote.": ".$es_inner_quote.$EMPTY_STRING.$es_inner_quote.", "; 
    $previous_wyd .= $es_inner_quote."cologne".$es_inner_quote.": ".$es_inner_quote.$EMPTY_STRING.$es_inner_quote.", "; 
    $previous_wyd .= $es_inner_quote."sydney".$es_inner_quote.": ".$es_inner_quote.$EMPTY_STRING.$es_inner_quote.", "; 
    $previous_wyd .= $es_inner_quote."madrit".$es_inner_quote.": ".$es_inner_quote.$EMPTY_STRING.$es_inner_quote.", "; 
    $previous_wyd .= $es_inner_quote."rio".$es_inner_quote.": ".$es_inner_quote.$EMPTY_STRING.$es_inner_quote."}";
    
    $consent = $EMPTY_STRING;
    $extra = RemoveSpecialCharacters($fields->[9]);
}

#
# ReadInternetSrcLine ($fields);
#
sub ReadInternetSrcLine
{
    my $fields = shift;
    $created_at = RemoveSpecialCharacters($fields->[0]);
    $first_name = RemoveSpecialCharacters($fields->[1]);
    $last_name = RemoveSpecialCharacters($fields->[2]);
    $email = RemoveSpecialCharacters($fields->[3]);
    $mobile = RemoveSpecialCharacters($fields->[4]);
    $address = RemoveSpecialCharacters($fields->[5]);
    $address2 = RemoveSpecialCharacters($fields->[6]);
    $parish = RemoveSpecialCharacters($fields->[7]);    
    $birth_date = RemoveSpecialCharacters($fields->[8]);
    $education = RemoveSpecialCharacters($fields->[9]);
    $study_field = RemoveSpecialCharacters($fields->[10]);
    $studying_from = RemoveSpecialCharacters($fields->[11]);
    $experience = RemoveSpecialCharacters($fields->[12]);
    
    $languages = "[{";
    $languages .= $es_inner_quote."name".$es_inner_quote.": ".$es_inner_quote.RemoveSpecialCharacters($fields->[13]).$es_inner_quote.", "; 
    $languages .= $es_inner_quote."level".$es_inner_quote.": ".$es_inner_quote.RemoveSpecialCharacters($fields->[14]).$es_inner_quote."}, {"; 
    $languages .= $es_inner_quote."name".$es_inner_quote.": ".$es_inner_quote.RemoveSpecialCharacters($fields->[15]).$es_inner_quote.", "; 
    $languages .= $es_inner_quote."level".$es_inner_quote.": ".$es_inner_quote.RemoveSpecialCharacters($fields->[16]).$es_inner_quote."}, {";
    $languages .= $es_inner_quote."name".$es_inner_quote.": ".$es_inner_quote.RemoveSpecialCharacters($fields->[17]).$es_inner_quote.", "; 
    $languages .= $es_inner_quote."level".$es_inner_quote.": ".$es_inner_quote.RemoveSpecialCharacters($fields->[18]).$es_inner_quote."}, {";
    $languages .= $es_inner_quote."name".$es_inner_quote.": ".$es_inner_quote.RemoveSpecialCharacters($fields->[19]).$es_inner_quote.", "; 
    $languages .= $es_inner_quote."level".$es_inner_quote.": ".$es_inner_quote.RemoveSpecialCharacters($fields->[20]).$es_inner_quote."}]";
    
    $interests = RemoveSpecialCharacters($fields->[21]);
    $departments = RemoveSpecialCharacters($fields->[22]);
    $availability = RemoveSpecialCharacters($fields->[23]);
    
    $previous_wyd = "{";
    $previous_wyd .= $es_inner_quote."attendance".$es_inner_quote.": ".$es_inner_quote.RemoveSpecialCharacters($fields->[24]).$es_inner_quote.", "; 
    $previous_wyd .= $es_inner_quote."paris".$es_inner_quote.": ".$es_inner_quote.RemoveSpecialCharacters($fields->[25]).$es_inner_quote.", "; 
    $previous_wyd .= $es_inner_quote."rome".$es_inner_quote.": ".$es_inner_quote.RemoveSpecialCharacters($fields->[26]).$es_inner_quote.", "; 
    $previous_wyd .= $es_inner_quote."toronto".$es_inner_quote.": ".$es_inner_quote.RemoveSpecialCharacters($fields->[27]).$es_inner_quote.", "; 
    $previous_wyd .= $es_inner_quote."cologne".$es_inner_quote.": ".$es_inner_quote.RemoveSpecialCharacters($fields->[28]).$es_inner_quote.", "; 
    $previous_wyd .= $es_inner_quote."sydney".$es_inner_quote.": ".$es_inner_quote.RemoveSpecialCharacters($fields->[29]).$es_inner_quote.", "; 
    $previous_wyd .= $es_inner_quote."madrit".$es_inner_quote.": ".$es_inner_quote.RemoveSpecialCharacters($fields->[30]).$es_inner_quote.", "; 
    $previous_wyd .= $es_inner_quote."rio".$es_inner_quote.": ".$es_inner_quote.RemoveSpecialCharacters($fields->[31]).$es_inner_quote."}";
    
    $consent = RemoveSpecialCharacters($fields->[32]);
    $extra = $EMPTY_STRING;
}

#
# ClearElasticSearch ();
#
sub ClearElasticSearch
{
    my $es_cmd = "curl -XDELETE ".$es_outer_quote."localhost:9200/$_index/$_type".$es_outer_quote;
    print "$es_cmd \n";
    system ($es_cmd);
}

#
# DeleteJSON ($_id);
#
sub DeleteJSON
{
    my $_id = shift;
    my $es_cmd = "curl -XDELETE ".$es_outer_quote."localhost:9200/$_index/$_type/$_id ".$es_outer_quote;
    system($es_cmd);
}

#
# CreateJSONMapping;
#
sub CreateJSONMapping
{
    my $es_mapping = $es_outer_quote."{".$es_inner_quote."properties".$es_inner_quote.": {";
    
    $es_mapping .= " ".$es_inner_quote."created_at".$es_inner_quote.": {";
    $es_mapping .= " ".$es_inner_quote."type".$es_inner_quote.": ".$es_inner_quote."string".$es_inner_quote.",";
    $es_mapping .= " ".$es_inner_quote."index".$es_inner_quote.": ".$es_inner_quote."analyzed".$es_inner_quote." },";
    
    $es_mapping .= " ".$es_inner_quote."first_name".$es_inner_quote.": {";
    $es_mapping .= " ".$es_inner_quote."type".$es_inner_quote.": ".$es_inner_quote."string".$es_inner_quote.",";
    $es_mapping .= " ".$es_inner_quote."index".$es_inner_quote.": ".$es_inner_quote."not_analyzed".$es_inner_quote." },";
    
    $es_mapping .= " ".$es_inner_quote."last_name".$es_inner_quote.": {";
    $es_mapping .= " ".$es_inner_quote."type".$es_inner_quote.": ".$es_inner_quote."string".$es_inner_quote.",";
    $es_mapping .= " ".$es_inner_quote."index".$es_inner_quote.": ".$es_inner_quote."not_analyzed".$es_inner_quote." },";
    
    $es_mapping .= " ".$es_inner_quote."email".$es_inner_quote.": {";
    $es_mapping .= " ".$es_inner_quote."type".$es_inner_quote.": ".$es_inner_quote."string".$es_inner_quote.",";
    $es_mapping .= " ".$es_inner_quote."index".$es_inner_quote.": ".$es_inner_quote."not_analyzed".$es_inner_quote." },";
    
    $es_mapping .= " ".$es_inner_quote."mobile".$es_inner_quote.": {";
    $es_mapping .= " ".$es_inner_quote."type".$es_inner_quote.": ".$es_inner_quote."string".$es_inner_quote.",";
    $es_mapping .= " ".$es_inner_quote."index".$es_inner_quote.": ".$es_inner_quote."not_analyzed".$es_inner_quote." },";
    
    $es_mapping .= " ".$es_inner_quote."address".$es_inner_quote.": {";
    $es_mapping .= " ".$es_inner_quote."type".$es_inner_quote.": ".$es_inner_quote."string".$es_inner_quote.",";
    $es_mapping .= " ".$es_inner_quote."index".$es_inner_quote.": ".$es_inner_quote."not_analyzed".$es_inner_quote." },";
    
    $es_mapping .= " ".$es_inner_quote."address2".$es_inner_quote.": {";
    $es_mapping .= " ".$es_inner_quote."type".$es_inner_quote.": ".$es_inner_quote."string".$es_inner_quote.",";
    $es_mapping .= " ".$es_inner_quote."index".$es_inner_quote.": ".$es_inner_quote."not_analyzed".$es_inner_quote." },";
    
    $es_mapping .= " ".$es_inner_quote."parish".$es_inner_quote.": {";
    $es_mapping .= " ".$es_inner_quote."type".$es_inner_quote.": ".$es_inner_quote."string".$es_inner_quote." },";
    
    $es_mapping .= " ".$es_inner_quote."birth_date".$es_inner_quote.": {";
    $es_mapping .= " ".$es_inner_quote."type".$es_inner_quote.": ".$es_inner_quote."date".$es_inner_quote." },";
    
    $es_mapping .= " ".$es_inner_quote."education".$es_inner_quote.": {";
    $es_mapping .= " ".$es_inner_quote."type".$es_inner_quote.": ".$es_inner_quote."string".$es_inner_quote." },";
    
    $es_mapping .= " ".$es_inner_quote."study_field".$es_inner_quote.": {";
    $es_mapping .= " ".$es_inner_quote."type".$es_inner_quote.": ".$es_inner_quote."string".$es_inner_quote." },";
    
    $es_mapping .= " ".$es_inner_quote."studying_from".$es_inner_quote.": {";
    $es_mapping .= " ".$es_inner_quote."type".$es_inner_quote.": ".$es_inner_quote."string".$es_inner_quote." },";
    
    $es_mapping .= " ".$es_inner_quote."experience".$es_inner_quote.": {";
    $es_mapping .= " ".$es_inner_quote."type".$es_inner_quote.": ".$es_inner_quote."string".$es_inner_quote." },";
    
    $es_mapping .= " ".$es_inner_quote."languages".$es_inner_quote.": {";
    $es_mapping .= " ".$es_inner_quote."type".$es_inner_quote.": ".$es_inner_quote."nested".$es_inner_quote.",";
    $es_mapping .= " ".$es_inner_quote."properties".$es_inner_quote.": {";
    $es_mapping .= " ".$es_inner_quote."name".$es_inner_quote.": {";
    $es_mapping .= " ".$es_inner_quote."type".$es_inner_quote.": ".$es_inner_quote."string".$es_inner_quote." },";
    $es_mapping .= " ".$es_inner_quote."level".$es_inner_quote.": {";
    $es_mapping .= " ".$es_inner_quote."type".$es_inner_quote.": ".$es_inner_quote."string".$es_inner_quote." } } },";
    
    $es_mapping .= " ".$es_inner_quote."interests".$es_inner_quote.": {";
    $es_mapping .= " ".$es_inner_quote."type".$es_inner_quote.": ".$es_inner_quote."string".$es_inner_quote." },";
    
    $es_mapping .= " ".$es_inner_quote."departments".$es_inner_quote.": {";
    $es_mapping .= " ".$es_inner_quote."type".$es_inner_quote.": ".$es_inner_quote."string".$es_inner_quote." },";
    
    $es_mapping .= " ".$es_inner_quote."availability".$es_inner_quote.": {";
    $es_mapping .= " ".$es_inner_quote."type".$es_inner_quote.": ".$es_inner_quote."string".$es_inner_quote." },";
    
    
    $es_mapping .= " ".$es_inner_quote."previous_wyd".$es_inner_quote.": {";
    $es_mapping .= " ".$es_inner_quote."type".$es_inner_quote.": ".$es_inner_quote."object".$es_inner_quote.",";
    $es_mapping .= " ".$es_inner_quote."properties".$es_inner_quote.": {";
    $es_mapping .= " ".$es_inner_quote."attendance".$es_inner_quote.": {";
    $es_mapping .= " ".$es_inner_quote."type".$es_inner_quote.": ".$es_inner_quote."string".$es_inner_quote.",";
    $es_mapping .= " ".$es_inner_quote."index".$es_inner_quote.": ".$es_inner_quote."not_analyzed".$es_inner_quote." },";
    $es_mapping .= " ".$es_inner_quote."paris".$es_inner_quote.": {";
    $es_mapping .= " ".$es_inner_quote."type".$es_inner_quote.": ".$es_inner_quote."string".$es_inner_quote." },";
    $es_mapping .= " ".$es_inner_quote."rome".$es_inner_quote.": {";
    $es_mapping .= " ".$es_inner_quote."type".$es_inner_quote.": ".$es_inner_quote."string".$es_inner_quote." },";
    $es_mapping .= " ".$es_inner_quote."toronto".$es_inner_quote.": {";
    $es_mapping .= " ".$es_inner_quote."type".$es_inner_quote.": ".$es_inner_quote."string".$es_inner_quote." },";
    $es_mapping .= " ".$es_inner_quote."cologne".$es_inner_quote.": {";
    $es_mapping .= " ".$es_inner_quote."type".$es_inner_quote.": ".$es_inner_quote."string".$es_inner_quote." },";
    $es_mapping .= " ".$es_inner_quote."sydney".$es_inner_quote.": {";
    $es_mapping .= " ".$es_inner_quote."type".$es_inner_quote.": ".$es_inner_quote."string".$es_inner_quote." },";
    $es_mapping .= " ".$es_inner_quote."madrit".$es_inner_quote.": {";
    $es_mapping .= " ".$es_inner_quote."type".$es_inner_quote.": ".$es_inner_quote."string".$es_inner_quote." },";
    $es_mapping .= " ".$es_inner_quote."rio".$es_inner_quote.": {";
    $es_mapping .= " ".$es_inner_quote."type".$es_inner_quote.": ".$es_inner_quote."string".$es_inner_quote." } } },";
    
    
    $es_mapping .= " ".$es_inner_quote."consent".$es_inner_quote.": {";
    $es_mapping .= " ".$es_inner_quote."type".$es_inner_quote.": ".$es_inner_quote."string".$es_inner_quote.",";
    $es_mapping .= " ".$es_inner_quote."index".$es_inner_quote.": ".$es_inner_quote."not_analyzed".$es_inner_quote." },";
    
    $es_mapping .= " ".$es_inner_quote."extra".$es_inner_quote.": {";
    $es_mapping .= " ".$es_inner_quote."type".$es_inner_quote.": ".$es_inner_quote."string".$es_inner_quote." }";
        
    $es_mapping .= "} }".$es_outer_quote;
    
    my $es_cmd = "curl -XPUT ".$es_outer_quote."localhost:9200/$_index/_mapping/$_type".$es_outer_quote." -d ".$es_mapping;
    #print "$es_cmd \n";
    my $result = `$es_cmd`;
    
}

#
# CreateJSON ($_id);
#
sub CreateJSON
{
    my $es_json = $es_outer_quote."{";
    $es_json .= " ".$es_inner_quote."created_at".$es_inner_quote.": ".$es_inner_quote.$created_at.$es_inner_quote.",";
    $es_json .= " ".$es_inner_quote."first_name".$es_inner_quote.": ".$es_inner_quote.$first_name.$es_inner_quote.",";
    $es_json .= " ".$es_inner_quote."last_name".$es_inner_quote.": ".$es_inner_quote.$last_name.$es_inner_quote.",";
    $es_json .= " ".$es_inner_quote."email".$es_inner_quote.": ".$es_inner_quote.$email.$es_inner_quote.",";
    $es_json .= " ".$es_inner_quote."mobile".$es_inner_quote.": ".$es_inner_quote.$mobile.$es_inner_quote.",";
    $es_json .= " ".$es_inner_quote."address".$es_inner_quote.": ".$es_inner_quote.$address.$es_inner_quote.",";
    $es_json .= " ".$es_inner_quote."address2".$es_inner_quote.": ".$es_inner_quote.$address2.$es_inner_quote.",";
    $es_json .= " ".$es_inner_quote."parish".$es_inner_quote.": ".$es_inner_quote.$parish.$es_inner_quote.",";
    $es_json .= " ".$es_inner_quote."birth_date".$es_inner_quote.": ".$es_inner_quote.$birth_date.$es_inner_quote.",";
    $es_json .= " ".$es_inner_quote."education".$es_inner_quote.": ".$es_inner_quote.$education.$es_inner_quote.",";
    $es_json .= " ".$es_inner_quote."study_field".$es_inner_quote.": ".$es_inner_quote.$study_field.$es_inner_quote.",";
    $es_json .= " ".$es_inner_quote."studying_from".$es_inner_quote.": ".$es_inner_quote.$studying_from.$es_inner_quote.",";
    $es_json .= " ".$es_inner_quote."experience".$es_inner_quote.": ".$es_inner_quote.$experience.$es_inner_quote.",";
    $es_json .= " ".$es_inner_quote."languages".$es_inner_quote.": ".$languages.",";
    $es_json .= " ".$es_inner_quote."interests".$es_inner_quote.": ".$es_inner_quote.$interests.$es_inner_quote.",";
    $es_json .= " ".$es_inner_quote."departments".$es_inner_quote.": ".$es_inner_quote.$departments.$es_inner_quote.",";
    $es_json .= " ".$es_inner_quote."availability".$es_inner_quote.": ".$es_inner_quote.$availability.$es_inner_quote.",";
    $es_json .= " ".$es_inner_quote."previous_wyd".$es_inner_quote.": ".$previous_wyd.",";
    $es_json .= " ".$es_inner_quote."consent".$es_inner_quote.": ".$es_inner_quote.$consent.$es_inner_quote.",";
    $es_json .= " ".$es_inner_quote."extra".$es_inner_quote.": ".$es_inner_quote.$extra.$es_inner_quote;
    $es_json .= "}".$es_outer_quote;
    
    my $es_cmd = "curl -XPUT ".$es_outer_quote."localhost:9200/$_index/$_type/$_id".$es_outer_quote." -d ".$es_json;
    #print "$es_cmd \n";
    my $result = `$es_cmd`;
    
}


##########################SCRIPT##############################

# Clear Elastic Search
ClearElasticSearch();

# Create mapping for person type
CreateJSONMapping();

# Create JSONs from Paper Version

open ($csv_file_handle, '<:encoding(utf8)', $PAPER_SRC) or die "Could not open '$PAPER_SRC' $!\n";
$csv->getline( $csv_file_handle );
$_id = 0;
while (my $fields = $csv->getline( $csv_file_handle )) 
{
    $_id++;
    ReadPaperSrcLine($fields);
    DeleteJSON($_id);
    CreateJSON($_id);
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
    $_id++;
    ReadInternetSrcLine($fields);
    DeleteJSON($_id);
    CreateJSON($_id);
}
if (not $csv->eof) 
{
    $csv->error_diag();
}
close $csv_file_handle;


