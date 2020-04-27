export EXPAC_BUILDER_LIBDIR=$(dirname "${BASH_SOURCE[0]}")
export EXPAC_BUILDER_VERSION="0.1.0"

source "${EXPAC_BUILDER_LIBDIR}/config.sh"
source "${EXPAC_BUILDER_LIBDIR}/builders.sh"
source "${EXPAC_BUILDER_LIBDIR}/package.sh"
