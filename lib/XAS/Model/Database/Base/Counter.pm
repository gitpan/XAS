package XAS::Model::Database::Base::Counter;

our $VERSION = '0.01';

use XAS::Class
  version => $VERSION,
  base    => 'DBIx::Class::Core',
  mixin   => 'XAS::Model::DBM'
;

__PACKAGE__->load_components( qw/ InflateColumn::DateTime OptimisticLocking / );
__PACKAGE__->table( 'counter' );
__PACKAGE__->add_columns(
    id => {
        data_type         => 'bigint',
        is_auto_increment => 1,
        sequence          => 'counter_id_seq',
        is_nullable       => 0
    },
    name => {
        data_type   => 'varchar',
        size        => 32,
        is_nullable => 0
    },
    value => {
        data_type   => 'bigint',
        is_nullable => 0
    },
    revision => {
        data_type   => 'bigint',
        is_nullable => 1
    }
);

__PACKAGE__->set_primary_key( 'id' );
__PACKAGE__->optimistic_locking_strategy('version');
__PACKAGE__->optimistic_locking_version_column('revision');

sub table_name {
    return __PACKAGE__;
}

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;

    $sqlt_table->add_index(name => 'counter_name_idx', fields => ['name']);

}

1;

