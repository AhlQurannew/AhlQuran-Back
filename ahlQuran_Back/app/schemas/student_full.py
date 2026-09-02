from pydantic import BaseModel, EmailStr, Field, ConfigDict
from typing import Optional, List, Any
from datetime import date

class PersonalInfo(BaseModel):
    model_config = ConfigDict(populate_by_name=True)
    
    first_name_ar: str = Field(alias="firstNameAr")
    last_name_ar: str = Field(alias="lastNameAr")
    first_name_en: Optional[str] = Field(None, alias="firstNameEn")
    last_name_en: Optional[str] = Field(None, alias="lastNameEn")
    sex: Optional[str] = None
    date_of_birth: Optional[str] = Field(None, alias="dateOfBirth")
    place_of_birth: Optional[str] = Field(None, alias="placeOfBirth")
    home_address: Optional[str] = Field(None, alias="homeAddress")
    nationality: Optional[str] = None
    father_status: Optional[str] = Field(None, alias="fatherStatus")
    mother_status: Optional[str] = Field(None, alias="motherStatus")

class AccountInfo(BaseModel):
    model_config = ConfigDict(populate_by_name=True)
    
    username: str
    passcode: str
    account_type: Optional[str] = Field(None, alias="accountType")

class ContactInfo(BaseModel):
    model_config = ConfigDict(populate_by_name=True)
    
    phone_number: Optional[str] = Field(None, alias="phoneNumber")
    email: Optional[EmailStr] = None

class GuardianInfo(BaseModel):
    model_config = ConfigDict(populate_by_name=True)
    
    guardian_id: Optional[int] = Field(None, alias="guardianId")
    first_name: Optional[str] = Field(None, alias="firstName")
    last_name: Optional[str] = Field(None, alias="lastName")
    email: Optional[EmailStr] = None
    relationship: Optional[str] = None
    guardian_contact_id: Optional[int] = Field(None, alias="guardianContactId")
    guardian_account_id: Optional[int] = Field(None, alias="guardianAccountId")
    home_address: Optional[str] = Field(None, alias="homeAddress")
    job: Optional[str] = None
    profile_image: Optional[str] = Field(None, alias="profileImage")

class LectureInfo(BaseModel):
    model_config = ConfigDict(populate_by_name=True)
    
    lecture_id: int = Field(alias="lectureId")
    lecture_name_ar: Optional[str] = Field(None, alias="lectureNameAr")
    lecture_name_en: Optional[str] = Field(None, alias="lectureNameEn")

class FormalEducationInfo(BaseModel):
    model_config = ConfigDict(populate_by_name=True)
    
    academic_level: Optional[str] = Field(None, alias="academicLevel")
    grade: Optional[str] = None
    school_name: Optional[str] = Field(None, alias="schoolName")

class StudentCreateFull(BaseModel):
    personalInfo: PersonalInfo
    accountInfo: AccountInfo
    contactInfo: ContactInfo
    guardian: GuardianInfo
    lectures: List[LectureInfo] = []
    formalEducationInfo: FormalEducationInfo

