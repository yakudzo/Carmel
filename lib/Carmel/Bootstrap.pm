package Carmel::Bootstrap;
use Config;
use Module::CoreList;

my %environment;
sub modules { %{$environment{modules}} }
sub inc  { @{$environment{inc}} }
sub path { @{$environment{path}} }
sub base { $environment{base} }

sub environment {
    my($class, %args) = @_;
    %environment = %args;
}

sub bootstrap {
    my $class = shift;
    unshift @INC,
      Carmel::Bootstrap::FastINC->new($class->modules),
      $class->inc,
      Carmel::Bootstrap::Guard->new;
}

package Carmel::Bootstrap::FastINC;

sub new {
    my($class, %modules) = @_;
    bless \%modules, $class;
}

sub Carmel::Bootstrap::FastINC::INC {
    my($self, $file) = @_;

    if ($self->{$file}) {
        open my $fh, '<', $self->{$file}
          or die "Could not load $self->{$file}: $!";
        $INC{$file} = $self->{$file};
        return $fh;
    }
}

package Carmel::Bootstrap::Guard;

sub new {
    my $class = shift;
    bless { corelist => {} }, $class;
}

sub _package {
    my $file = shift;
    $file =~ s/\.pm$//;
    $file =~ s!/!::!g;
    $file;
}

sub Carmel::Bootstrap::Guard::INC {
    my($self, $file) = @_;

    # Config_heavy.pl etc.
    return if $file =~ /\.pl$/;

    my $mod = _package($file);
    my @caller = caller 0;

    # eval { require Module }
    return if $caller[3] =~ /^\(eval/ or defined $caller[6];

    # core module calling another module is considered core, too.
    # FIXME: Updated core module might call a non-core package
    if ($self->{corelist}{$caller[0]}) {
        $self->{corelist}{$mod} = 1;
        return;
    }

    # core module
    if ($Module::CoreList::version{$]+0}{$mod}) {
        $self->{corelist}{$mod} = 1;
        return;
    }

    # Module::Runtime::use_package_optimistically tries to parse this message.
    die "Can't locate $file in \@INC (You may need to add `requires '$mod';` to your cpanfile and run carmel install) (\@INC contains: @INC) at $caller[1] line $caller[2].\n";
}

1;

__END__
