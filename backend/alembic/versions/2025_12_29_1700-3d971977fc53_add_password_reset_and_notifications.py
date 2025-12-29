"""Add password reset and notifications

Revision ID: 3d971977fc53
Revises: d5644ef4a6ac
Create Date: 2025-12-29 17:00:07.138890+00:00

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '3d971977fc53'
down_revision = 'd5644ef4a6ac'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Agregar campos de reset de contraseña a users
    op.add_column('users', sa.Column('reset_token', sa.String(length=255), nullable=True))
    op.add_column('users', sa.Column('reset_token_expires', sa.DateTime(), nullable=True))
    
    # Crear tabla de notificaciones
    op.create_table('notifications',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('user_id', sa.Integer(), nullable=False),
        sa.Column('title', sa.String(length=255), nullable=False),
        sa.Column('message', sa.Text(), nullable=True),
        sa.Column('type', sa.String(length=50), nullable=True),
        sa.Column('related_id', sa.Integer(), nullable=True),
        sa.Column('is_read', sa.Boolean(), server_default='false', nullable=False),
        sa.Column('created_at', sa.DateTime(), server_default=sa.text('now()'), nullable=False),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index('idx_notifications_user_id', 'notifications', ['user_id'])
    op.create_index('idx_notifications_is_read', 'notifications', ['is_read'])


def downgrade() -> None:
    # Eliminar tabla de notificaciones
    op.drop_index('idx_notifications_is_read', table_name='notifications')
    op.drop_index('idx_notifications_user_id', table_name='notifications')
    op.drop_table('notifications')
    
    # Eliminar campos de reset de contraseña
    op.drop_column('users', 'reset_token_expires')
    op.drop_column('users', 'reset_token')
