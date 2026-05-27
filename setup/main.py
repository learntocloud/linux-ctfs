from __future__ import annotations

from flags import derive_verification_secret, generate_flags, generate_instance_id, hash_flags
from state import write_ctf_state
from system import configure_system
from challenges import setup_all_challenges


def main() -> None:
    flags = generate_flags()
    instance_id = generate_instance_id()
    verification_secret = derive_verification_secret(instance_id)

    configure_system()
    write_ctf_state(hash_flags(flags), instance_id, verification_secret)
    setup_all_challenges(flags)


if __name__ == "__main__":
    main()
