package LibreCat::Cmd::citation;

use Catmandu::Sane;
use LibreCat::Citation;
use Carp;
use parent qw(LibreCat::Cmd);

sub description {
    return <<EOF;
Usage:

librecat citation add <FILE>
librecat citation delete <id> | <IDFILE>
librecat citation export
librecat citation get <id> | <IDFILE>

EOF
}

sub command_opt_spec {
    my ($class) = @_;
    ();
}

sub opts {
    state $opts = $_[1];
}

sub command {
    my ($self, $opts, $args) = @_;

    $self->opts($opts);

    my $commands = qr/export|get|add|delete/;

    unless (@$args) {
        $self->usage_error("should be one of $commands");
    }

    my $cmd = shift @$args;

    unless ($cmd =~ /^$commands$/) {
        $self->usage_error("should be one of $commands");
    }

    binmode(STDOUT, ":encoding(utf-8)");

    if ($cmd eq 'export') {
        return $self->_export();
    }
    elsif ($cmd eq 'get') {
        my $id = shift @$args;

        return $self->id_or_file(
            $id,
            sub {
                $self->_get(shift);
            }
        );
    }
    elsif ($cmd eq 'add') {
        return $self->_add(@$args);
    }
    elsif ($cmd eq 'delete') {
        my $id = shift @$args;

        return $self->id_or_file(
            $id,
            sub {
                $self->_delete(shift);
            }
        );
    }
}

sub _export {
    my ($self) = @_;

    my $it;

    $it = LibreCat::Citation->new();

    my $exporter = Catmandu->exporter('YAML');
    $exporter->add_many($it);
    $exporter->commit;

    return 0;
}

sub _get {
    my ($self, $id) = @_;

    croak "usage: $0 get <id>" unless defined($id);

    my $bag = LibreCat::Citation->new();
    my $data = $bag->get($id);

    Catmandu->export($data, 'YAML') if $data;

    return $data ? 0 : 2;
}

sub _add {
    my ($self, $file) = @_;

    croak "usage: $0 add <FILE>" unless defined($file) && -r $file;

    my $ret = 0;
    my $importer = Catmandu->importer('YAML', file => $file);

    my $bag = LibreCat::Citation->new();
    $bag->add_many(
        $importer,
        on_validation_error => sub {
            my ($rec, $errors) = @_;
            say STDERR join("\n",
                $rec->{_id}, "ERROR: not a valid citation record",map {
                    $_->localize();
                } @$errors);
            $ret = 2;
        },
        on_success => sub {
            my ($rec) = @_;
            say "added $rec->{_id}";
        },
    );

    $ret;
}

sub _delete {
    my ($self, $id) = @_;

    croak "usage: $0 delete <id>" unless defined($id);

    my $bag = LibreCat::Citation->new();

    if ($bag->delete($id)) {
        say "deleted $id";
        return 0;
    }
    else {
        say STDERR "ERROR: delete $id failed";
        return 2;
    }
}

1;

__END__

=pod

=head1 NAME

LibreCat::Cmd::citation - manage librecat citations

=head1 SYNOPSIS

    librecat citation export [options] [<cql-query>]
    librecat citation add    [options] <FILE>
    librecat citation get    [options] <id> | <IDFILE>
    librecat citation delete [options] <id> | <IDFILE>
    librecat citation valid  [options] <FILE>

=cut
