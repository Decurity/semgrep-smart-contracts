use anchor_lang::prelude::*;

declare_id!("Fg6PaFpoGXkYsidMpWTK6W2BeZ7FEfcYkg476zPFsLnS");

#[program]
pub mod closing_accounts_insecure {
    use super::*;

    pub fn close_unsafe(ctx: Context<Close>) -> ProgramResult {
        let dest_starting_lamports = ctx.accounts.destination.lamports();

        **ctx.accounts.destination.lamports.borrow_mut() = dest_starting_lamports
            .checked_add(ctx.accounts.account_to_close.to_account_info().lamports())
            .unwrap();
        
        // ruleid: solana-insecure-account-closing
        **ctx.accounts.account_to_close.to_account_info().lamports.borrow_mut() = 0;

        Ok(())
    }

    pub fn close_safe(ctx: Context<Close>) -> ProgramResult {
        let dest_starting_lamports = ctx.accounts.destination.lamports();

        let account = ctx.accounts.account.to_account_info();
        **ctx.accounts.destination.lamports.borrow_mut() = dest_starting_lamports
            .checked_add(account.lamports())
            .unwrap();
        // ok: solana-insecure-account-closing
        **account.lamports.borrow_mut() = 0;

        let mut data = account.try_borrow_mut_data()?;
        for byte in data.deref_mut().iter_mut() {
            *byte = 0;
        }

        let dst: &mut [u8] = &mut data;
        let mut cursor = Cursor::new(dst);
        cursor.write_all(&CLOSED_ACCOUNT_DISCRIMINATOR)?;

        Ok(())
    }
}

#[derive(Accounts)]
pub struct Close<'info> {
    account_to_close: Account<'info, Data>,
    destination: AccountInfo<'info>,
}

#[account]
pub struct Data {
    data: u64,
}
