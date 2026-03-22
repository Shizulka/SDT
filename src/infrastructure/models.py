from typing import Optional
import datetime

from sqlalchemy import CHAR, DateTime, Text, text
from sqlalchemy.dialects.mysql import BIGINT
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column

class Base(DeclarativeBase):
    pass


class Note(Base):
    __tablename__ = 'note'

    note_id: Mapped[int] = mapped_column(BIGINT(20, unsigned=True), primary_key=True)
    title: Mapped[str] = mapped_column(CHAR(100), nullable=False)
    created_at: Mapped[datetime.datetime] = mapped_column(DateTime, nullable=False, server_default=text('current_timestamp()'))
    conten: Mapped[Optional[str]] = mapped_column(Text)
