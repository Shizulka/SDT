from datetime import datetime
import datetime
from src.infrastructure.models import Note
from src.repo.note_repo import NoteRepository


class NoteService:
    def __init__(self, db):
        self.repository = NoteRepository(db , Note)


    def create_note (self , title : str , conten : str ):
        new_note = Note (title=title , conten = conten )

        return self.repository.create(new_note)