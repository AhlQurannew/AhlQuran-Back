from pydantic import BaseModel, EmailStr, Field
from datetime import datetime
from typing import Optional, List

# Import or Redefine nested models matching frontend structure
class PersonalInfo(BaseModel):
    firstNameAr: Optional[str] = None
    lastNameAr: Optional[str] = None
    firstNameEn: Optional[str] = None
    lastNameEn: Optional[str] = None
    sex: Optional[str] = None
    dateOfBirth: Optional[str] = None
    placeOfBirth: Optional[str] = None
    homeAddress: Optional[str] = None
    nationality: Optional[str] = None
    fatherStatus: Optional[str] = None
    motherStatus: Optional[str] = None

class AccountInfo(BaseModel):
    accountId: Optional[int] = None
    username: Optional[str] = None
    passcode: Optional[str] = None # Usually shouldn't return this, but frontend might expect it
    accountType: Optional[str] = None

class ContactInfo(BaseModel):
    phoneNumber: Optional[str] = None
    email: Optional[str] = None

class GuardianInfo(BaseModel):
    guardianId: Optional[int] = None
    firstName: Optional[str] = None
    lastName: Optional[str] = None
    relationship: Optional[str] = None
    guardianContactId: Optional[int] = None
    guardianAccountId: Optional[int] = None
    homeAddress: Optional[str] = None
    job: Optional[str] = None
    profileImage: Optional[str] = None
    email: Optional[str] = None # Added for mapping convenience

class LectureInfo(BaseModel):
    lectureId: int
    lectureNameAr: Optional[str] = None
    lectureNameEn: Optional[str] = None

class FormalEducationInfo(BaseModel):
    academicLevel: Optional[str] = None
    grade: Optional[str] = None
    schoolName: Optional[str] = None

class MedicalInfo(BaseModel):
    medicalCondition: Optional[str] = None
    notes: Optional[str] = None

class SubscriptionInfo(BaseModel):
    subscriptionId: Optional[int] = None
    status: Optional[str] = None

class StudentRelations(BaseModel):
    pass

class StudentBase(BaseModel):
    firstname: str = Field(..., min_length=1, max_length=50, example="John")
    lastname: str = Field(..., min_length=1, max_length=50, example="Doe")
    email: EmailStr = Field(..., example="john.doe@example.com")
    parent_name: Optional[str] = Field(None, max_length=255, example="Jane Doe")
    parent_phone: Optional[str] = Field(None, max_length=20, example="+1234567890")
    guardian_email: Optional[EmailStr] = Field(None, example="guardian@example.com")
    golden: Optional[bool] = Field(False, example=False)


class StudentCreate(StudentBase):
    password: str = Field(..., min_length=6, example="securepassword")


class StudentUpdate(BaseModel):
    firstname: Optional[str] = Field(None, min_length=1, max_length=50)
    lastname: Optional[str] = Field(None, min_length=1, max_length=50)
    email: Optional[EmailStr] = None
    parent_name: Optional[str] = Field(None, max_length=255)
    parent_phone: Optional[str] = Field(None, max_length=20)
    guardian_email: Optional[EmailStr] = None
    golden: Optional[bool] = None


class StudentResponse(BaseModel):
    # Keep flat fields if needed for other endpoints, but frontend mainly uses nested
    id: int
    user_id: int
    
    # Nested structures matching frontend Student.fromJson
    personalInfo: PersonalInfo
    accountInfo: AccountInfo
    contactInfo: ContactInfo
    medicalInfo: MedicalInfo
    guardian: GuardianInfo
    lectures: List[LectureInfo]
    formalEducationInfo: FormalEducationInfo
    subscriptionInfo: SubscriptionInfo
    student: Optional[StudentRelations] = None

    # Legacy flat fields (optional, to avoid breaking other things if any)
    firstname: Optional[str] = None
    lastname: Optional[str] = None
    email: Optional[str] = None
    enrollment_date: Optional[datetime] = None
    parent_name: Optional[str] = None
    parent_phone: Optional[str] = None
    guardian_email: Optional[str] = None
    golden: Optional[bool] = None
    is_active: Optional[bool] = None

    class Config:
        from_attributes = True


class StudentList(BaseModel):
    students: list[StudentResponse]
    total: int
