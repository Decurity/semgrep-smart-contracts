use anchor_lang::prelude::*;
use anchor_lang::solana_program;

declare_id!("Fg6PaFpoGXkYsidMpWTK6W2BeZ7FEfcYkg476zPFsLnS");

#[program]
pub mod arbitrary_cpi_insecure {
    use super::*;

    pub fn cpi(ctx: Context<Cpi>) -> ProgramResult {
        solana_program::program::invoke(
            // ruleid: solana-arbitrary-program-call
            &spl_token::instruction::transfer(
                ctx.accounts.token_program.key,
                ctx.accounts.source.key,
                ctx.accounts.destination.key,
                ctx.accounts.authority.key,
                &[],
                amount,
            )?,
            &[
                ctx.accounts.source.clone(),
                ctx.accounts.destination.clone(),
                ctx.accounts.authority.clone(),
            ],
        )
    }

    pub fn cpi_checked(ctx: Context<CpiChecked>) -> ProgramResult {
        solana_program::program::invoke(
            // ok: solana-arbitrary-program-call
            &spl_token::instruction::transfer(
                ctx.accounts.token_program.key,
                ctx.accounts.source.key,
                ctx.accounts.destination.key,
                ctx.accounts.authority.key,
                &[],
                amount,
            )?,
            &[
                ctx.accounts.source.clone(),
                ctx.accounts.destination.clone(),
                ctx.accounts.authority.clone(),
            ],
        )
    }

    pub fn cpi_checked2(ctx: Context<Cpi>) -> ProgramResult {
        if &spl_token::ID != ctx.accounts.token_program.key {
            return Err(ProgramError::IncorrectProgramId);
        }
        solana_program::program::invoke(
            // ok: solana-arbitrary-program-call
            &spl_token::instruction::transfer(
                ctx.accounts.token_program.key,
                ctx.accounts.source.key,
                ctx.accounts.destination.key,
                ctx.accounts.authority.key,
                &[],
                amount,
            )?,
            &[
                ctx.accounts.source.clone(),
                ctx.accounts.destination.clone(),
                ctx.accounts.authority.clone(),
            ],
        )
    }
}

#[derive(Accounts)]
pub struct Cpi<'info> {
    source: AccountInfo<'info>,
    destination: UncheckedAccount<'info>,
    authority: UncheckedAccount<'info>,
    token_program: AccountInfo<'info>,
}

#[derive(Accounts)]
pub struct CpiChecked<'info> {
    source: Account<'info, TokenAccount>,
    destination: Account<'info, TokenAccount>,
    authority: Signer<'info>,
    token_program: Program<'info, Token>,
}
