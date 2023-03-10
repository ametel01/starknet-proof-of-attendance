%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.math_cmp import is_le_felt
from starkware.starknet.common.syscalls import get_caller_address
from openzeppelin.access.accesscontrol.library import AccessControl
from utils.library import assert_valid_address

@event
func AdminAdded(address: felt) {
}

@event
func AdminRemoved(address: felt) {
}

@event
func EventMinterAdded(event_id: felt, account: felt) {
}

@event
func EventMinterRemoved(event_id: felt, account: felt) {
}

@storage_var
func PoapRoles_admins(address: felt) -> (is_admin: felt) {
}

@storage_var
func PoapRoles_minters(event_id: felt, account: felt) -> (is_minter: felt) {
}

namespace PoapRoles {
    func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        sender: felt
    ) {
        alloc_locals;
        let (is_admin) = PoapRoles_admins.read(sender);
        if (is_admin == FALSE) {
            PoapRoles_admins.write(sender, TRUE);
            return ();
        }
        return ();
    }

    func only_admin{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
        let (message_sender) = get_caller_address();
        assert_valid_address(message_sender);
        let (is_admin) = PoapRoles_admins.read(message_sender);
        with_attr error_message("Message sender is not admim") {
            assert is_admin = TRUE;
        }
        return ();
    }

    func is_event_minter{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        event_id: felt, account: felt
    ) -> felt {
        let (is_admin) = PoapRoles_admins.read(account);
        let (is_minter) = PoapRoles_minters.read(event_id, account);

        let cond = is_le_felt(1, is_admin + is_minter);

        return cond;
    }

    func only_event_minter{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        event_id: felt
    ) {
        let (message_sender) = get_caller_address();
        assert_valid_address(message_sender);
        let (is_admin) = PoapRoles_admins.read(message_sender);
        let (is_minter) = PoapRoles_minters.read(event_id, message_sender);
        with_attr error_message("Message sender is not admim or minter") {
            let cond = is_le_felt(1, is_admin + is_minter);
            assert cond = TRUE;
        }
        return ();
    }

    func add_event_minter{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        event_id: felt, account: felt
    ) {
        only_admin();
        only_event_minter(event_id);
        PoapRoles_minters.write(event_id, account, TRUE);
        EventMinterAdded.emit(event_id, account);
        return ();
    }

    func add_admin{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(account: felt) {
        only_admin();
        PoapRoles_admins.write(account, TRUE);
        AdminAdded.emit(account);
        return ();
    }

    func renounce_event_minter{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        event_id: felt
    ) {
        let (message_sender) = get_caller_address();
        PoapRoles_minters.write(event_id, message_sender, FALSE);
        EventMinterRemoved.emit(event_id, message_sender);
        return ();
    }

    func renounce_admin{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
        only_admin();
        let (message_sender) = get_caller_address();
        PoapRoles_admins.write(message_sender, FALSE);
        AdminRemoved.emit(message_sender);
        return ();
    }

    func remove_event_minter{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        event_id: felt, account: felt
    ) {
        only_admin();
        let (message_sender) = get_caller_address();
        PoapRoles_minters.write(event_id, account, FALSE);
        EventMinterRemoved.emit(event_id, message_sender);
        return ();
    }
}
