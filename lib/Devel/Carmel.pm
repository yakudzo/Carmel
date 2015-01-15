package Devel::Carmel;
use Module::CoreList;

sub _find_border {
    my($re, @entry) = @_;

    my $in = 0;
    for my $index (0..$#entry) {
        my $entry = $entry[$index];
        next if ref $entry;

        if ($entry =~ $re) {
            $in = 1, next;
        } elsif ($in) {
            return $index;
        }
    }

    return;
}

# This assumes it's run under carmel exec
my $base = $ENV{PERL_CARMEL_REPO} || "$ENV{HOME}/.cpanm/builds";
my $index = _find_border qr!$base/.*?/blib/(lib|arch)?$!, @INC;

if ($index) {
    splice @INC, $index, 0, __PACKAGE__->new(@INC[0..$index-1]);
}

sub _package {
    my $file = shift;
    $file =~ s/\.pm$//;
    $file =~ s!/!::!g;
    $file;
}

sub new {
    my($class, @inc) = @_;
    bless {
        inc => \@inc,
        corelist => {},
    }, $class;
}

sub Devel::Carmel::INC {
    my($self, $file) = @_;

    # Config_heavy.pl etc.
    return if $file =~ /\.pl$/;

    my $mod = _package($file);
    my @caller = caller 0;

    # eval { require Module }
    return if $caller[3] =~ /^\(eval/ or defined $caller[6];

    # FIXME: Updated core module calls a new package
    if ($self->{corelist}{$caller[0]}) {
        $self->{corelist}{$mod} = 1;
        return;
    }

    # core module
    if ($Module::CoreList::version{$]+0}{$mod}) {
        $self->{corelist}{$mod} = 1;
        return;
    }

    die "Can't locate $file in \@INC in Carmel artifacts (You may need to install the $mod module with carmel install) (\@INC contains: @{$self->{inc}}).\n";
}

1;
