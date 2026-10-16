# -*- coding: utf-8 -*-
import os

FRONTEND_ROOT = r"G:\CODING PROJECTS\ahl_el_quran"

def write_file(rel_path, content):
    full_path = os.path.join(FRONTEND_ROOT, rel_path)
    os.makedirs(os.path.dirname(full_path), exist_ok=True)
    with open(full_path, "w", encoding="utf-8") as f:
        f.write(content)
    print(f"Updated {full_path}")

# ==========================================
# 1. Update app/API/teacher.ts
# ==========================================
teacher_ts_path = os.path.join(FRONTEND_ROOT, "app", "API", "teacher.ts")
with open(teacher_ts_path, "r", encoding="utf-8") as f:
    teacher_content = f.read()

# Add statistics methods if not already present
if "getTeacherStatsSummary" not in teacher_content:
    stat_methods = """
// ================= TEACHER STATISTICS =================

const getTeacherStatsSummary = async (): Promise<any> => {
    const res = await axiosGlobal.get("/statistics/summary");
    return res.data;
};

const getTeacherAttendanceTrend = async (limit: number = 10): Promise<any> => {
    const res = await axiosGlobal.get("/statistics/attendance-trend", { params: { limit } });
    return res.data;
};

const getTeacherTopMemorizers = async (limit: number = 5): Promise<any> => {
    const res = await axiosGlobal.get("/statistics/top-memorizers", { params: { limit } });
    return res.data;
};

const getTeacherLectureDistribution = async (): Promise<any> => {
    const res = await axiosGlobal.get("/statistics/lecture-distribution");
    return res.data;
};

const getTeacherAchievementBreakdown = async (params?: {
    lecture_id?: number;
    student_id?: number;
    start_date?: string;
    end_date?: string;
}): Promise<{ normal: number; small: number; big: number }> => {
    const res = await axiosGlobal.get("/statistics/achievement-breakdown", { params });
    return res.data;
};

const getTeacherAttendanceBreakdown = async (params?: {
    lecture_id?: number;
    student_id?: number;
    start_date?: string;
    end_date?: string;
}): Promise<{ present: number; late: number; absent: number; excused: number; total: number }> => {
    const res = await axiosGlobal.get("/statistics/attendance-breakdown", { params });
    return res.data;
};

const getTeacherHalqaBreakdown = async (params: {
    lecture_id: number;
    start_date?: string;
    end_date?: string;
}): Promise<Array<{ student: string; pages: number }>> => {
    const res = await axiosGlobal.get("/statistics/halqa-breakdown", { params });
    return res.data;
};

const getTeacherProgressTimeline = async (params: {
    student_id: number;
    start_date?: string;
    end_date?: string;
}): Promise<Array<{ date: string; memorization: number; minorRev: number; majorRev: number }>> => {
    const res = await axiosGlobal.get("/statistics/progress-timeline", { params });
    return res.data;
};
"""
    # Insert before teacherAPI object
    idx = teacher_content.rfind("const teacherAPI = {")
    if idx != -1:
        teacher_content = teacher_content[:idx] + stat_methods + "\n" + teacher_content[idx:]
        
    # Add methods to teacherAPI export
    export_insert = """    // statistics
    getTeacherStatsSummary,
    getTeacherAttendanceTrend,
    getTeacherTopMemorizers,
    getTeacherLectureDistribution,
    getTeacherAchievementBreakdown,
    getTeacherAttendanceBreakdown,
    getTeacherHalqaBreakdown,
    getTeacherProgressTimeline,
};"""
    teacher_content = teacher_content.replace("deleteTeacherAttendance,\n};", "deleteTeacherAttendance,\n" + export_insert)
    write_file("app/API/teacher.ts", teacher_content)
else:
    print("teacher.ts already has statistics methods")

# ==========================================
# 2. Update app/API/reports.ts
# ==========================================
reports_ts = """import axios from "axios";
import { useAuthStore } from "@/store/authStore";

const API_URL = process.env.NEXT_PUBLIC_API_BASE_URL || process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000/api/v1";

const getAxiosClient = () => {
    const role = useAuthStore.getState().user?.role;
    const basePrefix = role === "TEACHER" ? "/teacher" : "/president";

    const client = axios.create({
        baseURL: `${API_URL}${basePrefix}`,
        headers: {
            "Content-Type": "application/json",
            "ngrok-skip-browser-warning": "true",
        },
    });

    client.interceptors.request.use((config) => {
        const directToken = typeof window !== "undefined" ? localStorage.getItem("access_token") : null;
        const zustandToken = useAuthStore.getState().accessToken;
        const token = directToken || zustandToken;

        if (token) {
            config.headers.Authorization = `Bearer ${token}`;
            config.headers["ngrok-skip-browser-warning"] = "true";
        }
        return config;
    });

    client.interceptors.response.use(
        (response) => response,
        (error) => {
            console.error("Reports API Error:", {
                message: error.message,
                response: error.response?.data,
                status: error.response?.status,
                url: error.config?.url,
            });

            if (error.response && error.response.status === 401) {
                if (typeof window !== "undefined" && !window.location.pathname.includes("/login")) {
                    localStorage.removeItem("access_token");
                    localStorage.removeItem("refresh_token");
                    window.location.href = "/login?expired=true";
                }
            }
            return Promise.reject(error);
        }
    );

    return client;
};

export interface StatsSummary {
    total_students: number;
    total_teachers?: number;
    total_supervisors?: number;
    present_today: number;
    total_pages_memorized: number;
    total_lectures: number;
}

export interface AttendanceRecord {
    date: string;
    present: number;
    absent: number;
    total: number;
    percentage: string;
}

export interface MemorizationRecord {
    student: string;
    pages: number;
    rank: number;
}

export interface LectureDistribution {
    className: string;
    students: number;
    percentage: string;
}

const getStatsSummary = async (): Promise<StatsSummary> => {
    const client = getAxiosClient();
    const res = await client.get("/statistics/summary");
    return res.data;
};

const getAttendanceTrend = async (limit: number = 10): Promise<AttendanceRecord[]> => {
    const client = getAxiosClient();
    const res = await client.get("/statistics/attendance-trend", {
        params: { limit },
    });
    return res.data;
};

const getTopMemorizers = async (limit: number = 5): Promise<MemorizationRecord[]> => {
    const client = getAxiosClient();
    const res = await client.get("/statistics/top-memorizers", {
        params: { limit },
    });
    return res.data;
};

const getLectureDistribution = async (): Promise<LectureDistribution[]> => {
    const client = getAxiosClient();
    const res = await client.get("/statistics/lecture-distribution");
    return res.data;
};

const getAchievementBreakdown = async (params?: {
    lecture_id?: number;
    student_id?: number;
    start_date?: string;
    end_date?: string;
}): Promise<{ normal: number; small: number; big: number }> => {
    const client = getAxiosClient();
    const res = await client.get("/statistics/achievement-breakdown", { params });
    return res.data;
};

const getAttendanceBreakdown = async (params?: {
    lecture_id?: number;
    student_id?: number;
    start_date?: string;
    end_date?: string;
}): Promise<{ present: number; late: number; absent: number; excused: number; total: number }> => {
    const client = getAxiosClient();
    const res = await client.get("/statistics/attendance-breakdown", { params });
    return res.data;
};

const getHalqaBreakdown = async (params: {
    lecture_id: number;
    start_date?: string;
    end_date?: string;
}): Promise<Array<{ student: string; pages: number }>> => {
    const client = getAxiosClient();
    const res = await client.get("/statistics/halqa-breakdown", { params });
    return res.data;
};

const getProgressTimeline = async (params: {
    student_id: number;
    start_date?: string;
    end_date?: string;
}): Promise<Array<{ date: string; memorization: number; minorRev: number; majorRev: number }>> => {
    const client = getAxiosClient();
    const res = await client.get("/statistics/progress-timeline", { params });
    return res.data;
};

const reportsAPI = {
    getStatsSummary,
    getAttendanceTrend,
    getTopMemorizers,
    getLectureDistribution,
    getAchievementBreakdown,
    getAttendanceBreakdown,
    getHalqaBreakdown,
    getProgressTimeline,
};

export default reportsAPI;
"""
write_file("app/API/reports.ts", reports_ts)

# ==========================================
# 3. Update components/reports/StatisticsTable.tsx
# ==========================================
statistics_table_tsx = """'use client';

import React, { useState, useEffect } from 'react';
import reportsAPI, { StatsSummary, AttendanceRecord, MemorizationRecord, LectureDistribution } from '@/app/API/reports';
import { Loader2 } from 'lucide-react';

export function StatisticsTable() {
  const [summary, setSummary] = useState<StatsSummary | null>(null);
  const [attendanceData, setAttendanceData] = useState<AttendanceRecord[]>([]);
  const [memorizationData, setMemorizationData] = useState<MemorizationRecord[]>([]);
  const [classData, setClassData] = useState<LectureDistribution[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function loadStats() {
      try {
        setLoading(true);
        const [sumRes, attRes, memRes, classRes] = await Promise.allSettled([
          reportsAPI.getStatsSummary(),
          reportsAPI.getAttendanceTrend(10),
          reportsAPI.getTopMemorizers(5),
          reportsAPI.getLectureDistribution()
        ]);

        if (sumRes.status === 'fulfilled') setSummary(sumRes.value);
        if (attRes.status === 'fulfilled') setAttendanceData(attRes.value || []);
        if (memRes.status === 'fulfilled') setMemorizationData(memRes.value || []);
        if (classRes.status === 'fulfilled') setClassData(classRes.value || []);
      } catch (err) {
        console.error('Failed to load statistics:', err);
      } finally {
        setLoading(false);
      }
    }
    loadStats();
  }, []);

  if (loading) {
    return (
      <div className="flex flex-col items-center justify-center p-16 space-y-4">
        <Loader2 className="w-10 h-10 animate-spin text-emerald-600" />
        <p className="text-sm font-semibold text-gray-500">جاري تحميل التقارير والإحصائيات...</p>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Summary Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="bg-gradient-to-br from-amber-400 to-amber-500 rounded-xl p-6 shadow-md">
          <h3 className="text-white text-sm font-semibold mb-2">إجمالي الطلاب</h3>
          <p className="text-white text-3xl font-bold">{summary?.total_students ?? 0}</p>
        </div>
        <div className="bg-gradient-to-br from-emerald-500 to-emerald-600 rounded-xl p-6 shadow-md">
          <h3 className="text-white text-sm font-semibold mb-2">الطلاب الحاضرون اليوم</h3>
          <p className="text-white text-3xl font-bold">{summary?.present_today ?? 0}</p>
        </div>
        <div className="bg-gradient-to-br from-amber-400 to-amber-500 rounded-xl p-6 shadow-md">
          <h3 className="text-white text-sm font-semibold mb-2">الصفحات المحفوظة</h3>
          <p className="text-white text-3xl font-bold">{summary?.total_pages_memorized ?? 0}</p>
        </div>
        <div className="bg-gradient-to-br from-emerald-500 to-emerald-600 rounded-xl p-6 shadow-md">
          <h3 className="text-white text-sm font-semibold mb-2">عدد الحلقات</h3>
          <p className="text-white text-3xl font-bold">{summary?.total_lectures ?? 0}</p>
        </div>
      </div>

      {/* Attendance Trend Table */}
      <div className="bg-white rounded-2xl border border-gray-100 shadow-sm overflow-hidden">
        <div className="bg-amber-500/85 text-white py-3 px-6 font-semibold text-sm">
          تقرير تطور الحضور
        </div>
        <div className="overflow-x-auto">
          {attendanceData.length === 0 ? (
            <div className="p-8 text-center text-sm text-gray-500">لا توجد سجلات حضور مسجلة حالياً</div>
          ) : (
            <table className="w-full border-collapse">
              <thead>
                <tr className="bg-teal-800 text-white border-b border-teal-900">
                  <th className="px-4 py-3.5 text-xs font-bold text-right uppercase tracking-wider">
                    التاريخ
                  </th>
                  <th className="px-4 py-3.5 text-xs font-bold text-center uppercase tracking-wider">
                    الحاضرون
                  </th>
                  <th className="px-4 py-3.5 text-xs font-bold text-center uppercase tracking-wider">
                    الغائبون
                  </th>
                  <th className="px-4 py-3.5 text-xs font-bold text-center uppercase tracking-wider">
                    الإجمالي
                  </th>
                  <th className="px-4 py-3.5 text-xs font-bold text-center uppercase tracking-wider">
                    نسبة الحضور
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {attendanceData.map((record, index) => (
                  <tr key={index} className="hover:bg-gray-50/40 transition-colors">
                    <td className="px-4 py-3.5 text-sm font-semibold text-gray-800">
                      {record.date}
                    </td>
                    <td className="px-4 py-3.5 text-sm text-center text-emerald-600 font-semibold">
                      {record.present}
                    </td>
                    <td className="px-4 py-3.5 text-sm text-center text-amber-600 font-semibold">
                      {record.absent}
                    </td>
                    <td className="px-4 py-3.5 text-sm text-center text-gray-700 font-semibold">
                      {record.total}
                    </td>
                    <td className="px-4 py-3.5 text-sm text-center">
                      <span className={`inline-flex items-center px-3 py-1 rounded-full text-xs font-semibold ${
                        parseFloat(record.percentage) >= 90 
                          ? 'bg-emerald-100 text-emerald-700'
                          : 'bg-amber-100 text-amber-700'
                      }`}>
                        {record.percentage}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
        <div className="px-6 py-3 border-t border-gray-100 bg-gray-50/50 text-xs text-gray-400">
          <span>
            عدد السجلات: <span className="font-semibold text-gray-600">{attendanceData.length}</span>
          </span>
        </div>
      </div>

      {/* Two column layout for memorization and class tables */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Memorization Progress Table */}
        <div className="bg-white rounded-2xl border border-gray-100 shadow-sm overflow-hidden">
          <div className="bg-amber-500/85 text-white py-3 px-6 font-semibold text-sm">
            عدد الصفحات المحفوظة لكل طالب
          </div>
          <div className="overflow-x-auto">
            {memorizationData.length === 0 ? (
              <div className="p-8 text-center text-sm text-gray-500">لا توجد إنجازات مسجلة للطلاب حالياً</div>
            ) : (
              <table className="w-full border-collapse">
                <thead>
                  <tr className="bg-teal-800 text-white border-b border-teal-900">
                    <th className="px-4 py-3.5 text-xs font-bold text-center uppercase tracking-wider w-16">
                      الترتيب
                    </th>
                    <th className="px-4 py-3.5 text-xs font-bold text-right uppercase tracking-wider">
                      اسم الطالب
                    </th>
                    <th className="px-4 py-3.5 text-xs font-bold text-center uppercase tracking-wider">
                      عدد الصفحات
                    </th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-100">
                  {memorizationData.map((record) => (
                    <tr key={record.rank} className="hover:bg-gray-50/40 transition-colors">
                      <td className="px-4 py-3.5 text-center">
                        <span className={`inline-flex items-center justify-center w-7 h-7 rounded-full text-xs font-bold ${
                          record.rank === 1 ? 'bg-amber-500 text-white' :
                          record.rank === 2 ? 'bg-gray-400 text-white' :
                          record.rank === 3 ? 'bg-amber-700 text-white' :
                          'bg-gray-200 text-gray-700'
                        }`}>
                          {record.rank}
                        </span>
                      </td>
                      <td className="px-4 py-3.5 text-sm font-semibold text-gray-800">
                        {record.student}
                      </td>
                      <td className="px-4 py-3.5 text-sm text-center">
                        <span className="inline-flex items-center px-3 py-1 rounded-full text-xs font-semibold bg-emerald-100 text-emerald-700">
                          {record.pages} صفحة
                        </span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>
          <div className="px-6 py-3 border-t border-gray-100 bg-gray-50/50 text-xs text-gray-400">
            <span>
              عدد الطلاب: <span className="font-semibold text-gray-600">{memorizationData.length}</span>
            </span>
          </div>
        </div>

        {/* Class Distribution Table */}
        <div className="bg-white rounded-2xl border border-gray-100 shadow-sm overflow-hidden">
          <div className="bg-amber-500/85 text-white py-3 px-6 font-semibold text-sm">
            توزيع الطلاب على الحلقات
          </div>
          <div className="overflow-x-auto">
            {classData.length === 0 ? (
              <div className="p-8 text-center text-sm text-gray-500">لا توجد حلقات مسجلة حالياً</div>
            ) : (
              <table className="w-full border-collapse">
                <thead>
                  <tr className="bg-teal-800 text-white border-b border-teal-900">
                    <th className="px-4 py-3.5 text-xs font-bold text-right uppercase tracking-wider">
                      اسم الحلقة
                    </th>
                    <th className="px-4 py-3.5 text-xs font-bold text-center uppercase tracking-wider">
                      عدد الطلاب
                    </th>
                    <th className="px-4 py-3.5 text-xs font-bold text-center uppercase tracking-wider">
                      النسبة المئوية
                    </th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-100">
                  {classData.map((record, index) => (
                    <tr key={index} className="hover:bg-gray-50/40 transition-colors">
                      <td className="px-4 py-3.5 text-sm font-semibold text-gray-800">
                        {record.className}
                      </td>
                      <td className="px-4 py-3.5 text-sm text-center text-gray-700 font-semibold">
                        {record.students}
                      </td>
                      <td className="px-4 py-3.5 text-sm text-center">
                        <div className="flex items-center justify-center gap-2">
                          <div className="flex-1 max-w-[100px] bg-gray-200 rounded-full h-2 overflow-hidden">
                            <div 
                              className="bg-emerald-500 h-full rounded-full transition-all"
                              style={{ width: record.percentage }}
                            />
                          </div>
                          <span className="text-xs font-semibold text-gray-700 min-w-[45px]">
                            {record.percentage}
                          </span>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>
          <div className="px-6 py-3 border-t border-gray-100 bg-gray-50/50 text-xs text-gray-400">
            <span>
              عدد الحلقات: <span className="font-semibold text-gray-600">{classData.length}</span>
            </span>
          </div>
        </div>
      </div>
    </div>
  );
}
"""
write_file("components/reports/StatisticsTable.tsx", statistics_table_tsx)

# ==========================================
# 4. Update app/statistics/achievement/page.tsx
# ==========================================
stat_achievement_page = """'use client';

import React, { useState, useEffect } from 'react';
import { AppLayout } from '@/components/layout/AppLayout';
import { Select } from '@/components/ui/Select';
import { Input } from '@/components/ui/Input';
import { Button } from '@/components/ui/Button';
import { ArrowRight, Loader2 } from 'lucide-react';
import { useAuthStore } from '@/store/authStore';
import teacherAPI from '@/app/API/teacher';
import lecturesAPI from '@/app/API/lectures';
import reportsAPI from '@/app/API/reports';

export default function AchievementStatsPage() {
  const user = useAuthStore((s) => s.user);
  const isTeacher = user?.role === 'TEACHER';

  const [halqaList, setHalqaList] = useState<{ label: string; value: string }[]>([
    { label: 'اختر الحلقة', value: '' },
  ]);
  const [studentList, setStudentList] = useState<{ label: string; value: string }[]>([
    { label: 'اختر الطالب', value: '' },
  ]);

  const [isShowingStats, setIsShowingStats] = useState(false);
  const [loading, setLoading] = useState(false);
  const [halqa, setHalqa] = useState('');
  const [student, setStudent] = useState('');
  const [startDate, setStartDate] = useState('2026-01-01');
  const [endDate, setEndDate] = useState(new Date().toISOString().split('T')[0]);

  const [chartData, setChartData] = useState([
    { label: 'حفظ', value: 0, color: 'bg-emerald-400' },
    { label: 'مراجعة صغرى', value: 0, color: 'bg-amber-400' },
    { label: 'مراجعة كبرى', value: 0, color: 'bg-blue-400' },
  ]);

  // Load lectures (episodes) - scoped to teacher if teacher
  useEffect(() => {
    async function loadLectures() {
      try {
        let lectures: any[] = [];
        if (isTeacher) {
          lectures = await teacherAPI.getMyLectures();
        } else {
          lectures = await lecturesAPI.getAllLectures();
        }
        const options = [
          { label: 'اختر الحلقة', value: '' },
          ...lectures.map((l: any) => ({
            label: l.lecture_name_ar || `حلقة ${l.lecture_id || l.id}`,
            value: String(l.lecture_id || l.id),
          })),
        ];
        setHalqaList(options);
      } catch (err) {
        console.error('Error loading lectures:', err);
      }
    }
    loadLectures();
  }, [isTeacher]);

  // Load students when halqa changes or initially
  useEffect(() => {
    async function loadStudents() {
      try {
        let students: any[] = [];
        const lectureIdNum = halqa ? Number(halqa) : undefined;
        if (isTeacher) {
          const res = await teacherAPI.getMyStudents({ lecture_id: lectureIdNum });
          students = res.students || [];
        } else {
          const res = await teacherAPI.getMyStudents({ lecture_id: lectureIdNum }).catch(() => ({ students: [] }));
          students = res.students || [];
        }
        const options = [
          { label: 'اختر الطالب', value: '' },
          ...students.map((s: any) => ({
            label: `${s.personalInfo?.firstNameAr || s.firstname || ''} ${s.personalInfo?.lastNameAr || s.lastname || ''}`.trim() || `طالب ${s.id}`,
            value: String(s.id),
          })),
        ];
        setStudentList(options);
        setStudent('');
      } catch (err) {
        console.error('Error loading students:', err);
      }
    }
    loadStudents();
  }, [halqa, isTeacher]);

  const maxChartValue = Math.max(10, ...chartData.map((d) => d.value)) + 5;

  const handleShowStats = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!halqa && !student) {
      alert('يرجى اختيار حلقة أو طالب على الأقل');
      return;
    }
    try {
      setLoading(true);
      const res = await reportsAPI.getAchievementBreakdown({
        lecture_id: halqa ? Number(halqa) : undefined,
        student_id: student ? Number(student) : undefined,
        start_date: startDate,
        end_date: endDate,
      });

      setChartData([
        { label: 'حفظ', value: res.normal || 0, color: 'bg-emerald-400' },
        { label: 'مراجعة صغرى', value: res.small || 0, color: 'bg-amber-400' },
        { label: 'مراجعة كبرى', value: res.big || 0, color: 'bg-blue-400' },
      ]);
      setIsShowingStats(true);
    } catch (err) {
      console.error('Error fetching achievement stats:', err);
      alert('حدث خطأ أثناء جلب بيانات الإنجاز');
    } finally {
      setLoading(false);
    }
  };

  const selectedHalqaLabel = halqaList.find((h) => h.value === halqa)?.label || 'الكل';
  const selectedStudentLabel = studentList.find((s) => s.value === student)?.label || 'الكل';

  return (
    <AppLayout title="إحصائيات الإنجاز" breadcrumb="الشؤون الإدارية / الإحصاءات / إحصائيات الإنجاز">
      <div className="max-w-5xl mx-auto space-y-6">
        {/* Banner Title */}
        <div className="bg-amber-500/85 text-white py-3.5 px-6 rounded-xl shadow-sm font-semibold text-sm flex items-center justify-between">
          <span>إحصائيات الإنجاز</span>
          {isShowingStats && (
            <button
              onClick={() => setIsShowingStats(false)}
              className="flex items-center gap-1.5 hover:text-amber-100 transition-colors cursor-pointer text-xs bg-white/20 px-3 py-1.5 rounded-lg"
            >
              <ArrowRight size={14} />
              العودة للنموذج
            </button>
          )}
        </div>

        {!isShowingStats ? (
          /* ─── FORM VIEW ─── */
          <div className="bg-white rounded-3xl border border-gray-100 shadow-sm p-8 sm:p-12">
            <form onSubmit={handleShowStats} className="max-w-2xl mx-auto space-y-8">
              <div className="space-y-6">
                <Select
                  label="الحلقة"
                  value={halqa}
                  onChange={(e) => setHalqa(e.target.value)}
                  options={halqaList}
                />

                <Select
                  label="الطالب"
                  value={student}
                  onChange={(e) => setStudent(e.target.value)}
                  options={studentList}
                />

                <div className="grid grid-cols-1 sm:grid-cols-2 gap-6">
                  <Input
                    label="تاريخ البداية"
                    type="date"
                    value={startDate}
                    onChange={(e) => setStartDate(e.target.value)}
                  />
                  <Input
                    label="تاريخ النهاية"
                    type="date"
                    value={endDate}
                    onChange={(e) => setEndDate(e.target.value)}
                  />
                </div>
              </div>

              <div className="pt-4 flex justify-center">
                <Button type="submit" size="lg" disabled={loading} className="px-12 rounded-xl text-base shadow-emerald-500/30 shadow-lg">
                  {loading ? <Loader2 className="w-5 h-5 animate-spin" /> : 'عرض الإحصائيات'}
                </Button>
              </div>
            </form>
          </div>
        ) : (
          /* ─── CHART VIEW ─── */
          <div className="bg-white rounded-3xl border border-gray-100 shadow-sm p-8 sm:p-12 space-y-12">
            {/* Header Info */}
            <div className="flex flex-wrap items-center justify-center gap-x-8 gap-y-3 text-sm font-semibold text-gray-700 bg-gray-50/50 p-4 rounded-2xl border border-gray-100">
              <span>الطالب: <span className="text-emerald-600">{selectedStudentLabel}</span></span>
              <span className="text-gray-300">|</span>
              <span>الحلقة: <span className="text-emerald-600">{selectedHalqaLabel}</span></span>
              <span className="text-gray-300">|</span>
              <span>من: <span className="text-emerald-600">{startDate}</span></span>
              <span className="text-gray-300">|</span>
              <span>إلى: <span className="text-emerald-600">{endDate}</span></span>
            </div>

            {/* Chart Section */}
            <div className="space-y-10">
              <h2 className="text-center text-xl font-bold text-gray-800">
                عدد الصفحات حسب نوع الإنجاز
              </h2>

              <div className="relative h-80 max-w-3xl mx-auto flex items-end justify-around pb-8 border-b-2 border-gray-100 pt-10 px-4">
                {/* Y-axis labels */}
                <div className="absolute left-0 top-0 bottom-8 flex flex-col justify-between text-xs text-gray-400 font-medium pr-4 border-r-2 border-gray-100">
                  <span>{Math.round(maxChartValue)}</span>
                  <span>{Math.round(maxChartValue * 0.75)}</span>
                  <span>{Math.round(maxChartValue * 0.5)}</span>
                  <span>{Math.round(maxChartValue * 0.25)}</span>
                  <span>0</span>
                </div>

                {/* Bars */}
                {chartData.map((item, index) => {
                  const heightPercent = (item.value / maxChartValue) * 100;
                  return (
                    <div key={index} className="h-full flex flex-col justify-end items-center gap-3 w-1/4 group relative">
                      {/* Tooltip on hover */}
                      <div className="absolute top-0 -translate-y-full opacity-0 group-hover:opacity-100 transition-opacity bg-gray-800 text-white text-xs font-bold py-1.5 px-3 rounded-lg pointer-events-none z-10 whitespace-nowrap shadow-lg mb-2">
                        {item.label}: {item.value} صفحة
                        <div className="absolute -bottom-1 left-1/2 -translate-x-1/2 w-2 h-2 bg-gray-800 rotate-45"></div>
                      </div>

                      {/* The Bar */}
                      <div
                        className={`w-full max-w-[60px] rounded-t-md ${item.color} transition-all duration-700 ease-out shadow-sm group-hover:brightness-110 cursor-pointer relative z-0`}
                        style={{ height: `${heightPercent}%` }}
                      ></div>

                      {/* X-axis label */}
                      <span className="text-sm font-semibold text-gray-600 absolute -bottom-8 whitespace-nowrap">
                        {item.label}
                      </span>
                    </div>
                  );
                })}
              </div>

              {/* Legend */}
              <div className="flex flex-wrap items-center justify-center gap-8 pt-6">
                {chartData.map((item, index) => (
                  <div key={index} className="flex items-center gap-2">
                    <span className={`w-3.5 h-3.5 rounded-full shadow-sm ${item.color}`}></span>
                    <span className="text-sm font-semibold text-gray-600">
                      {item.label}: <span className="text-gray-900">{item.value} صفحة</span>
                    </span>
                  </div>
                ))}
              </div>
            </div>
          </div>
        )}
      </div>
    </AppLayout>
  );
}
"""
write_file("app/statistics/achievement/page.tsx", stat_achievement_page)

# ==========================================
# 5. Update app/statistics/attendance/page.tsx
# ==========================================
stat_attendance_page = """'use client';

import React, { useState, useEffect } from 'react';
import { AppLayout } from '@/components/layout/AppLayout';
import { Select } from '@/components/ui/Select';
import { Input } from '@/components/ui/Input';
import { Button } from '@/components/ui/Button';
import { ArrowRight, Users, Loader2 } from 'lucide-react';
import { useAuthStore } from '@/store/authStore';
import teacherAPI from '@/app/API/teacher';
import lecturesAPI from '@/app/API/lectures';
import reportsAPI from '@/app/API/reports';

export default function AttendanceStatsPage() {
  const user = useAuthStore((s) => s.user);
  const isTeacher = user?.role === 'TEACHER';

  const [halqaList, setHalqaList] = useState<{ label: string; value: string }[]>([
    { label: 'اختر الحلقة', value: '' },
  ]);
  const [studentList, setStudentList] = useState<{ label: string; value: string }[]>([
    { label: 'جميع الطلاب (الكل)', value: '' },
  ]);

  const [isShowingStats, setIsShowingStats] = useState(false);
  const [loading, setLoading] = useState(false);
  const [halqa, setHalqa] = useState('');
  const [student, setStudent] = useState('');
  const [startDate, setStartDate] = useState('2026-01-01');
  const [endDate, setEndDate] = useState(new Date().toISOString().split('T')[0]);

  const [attendanceData, setAttendanceData] = useState({
    present: 0,
    late: 0,
    absent: 0,
    excused: 0,
    total: 0,
  });

  // Load lectures (episodes) - scoped to teacher
  useEffect(() => {
    async function loadLectures() {
      try {
        let lectures: any[] = [];
        if (isTeacher) {
          lectures = await teacherAPI.getMyLectures();
        } else {
          lectures = await lecturesAPI.getAllLectures();
        }
        const options = [
          { label: 'اختر الحلقة', value: '' },
          ...lectures.map((l: any) => ({
            label: l.lecture_name_ar || `حلقة ${l.lecture_id || l.id}`,
            value: String(l.lecture_id || l.id),
          })),
        ];
        setHalqaList(options);
      } catch (err) {
        console.error('Error loading lectures:', err);
      }
    }
    loadLectures();
  }, [isTeacher]);

  // Load students for the selected halqa
  useEffect(() => {
    async function loadStudents() {
      try {
        let students: any[] = [];
        const lectureIdNum = halqa ? Number(halqa) : undefined;
        if (isTeacher) {
          const res = await teacherAPI.getMyStudents({ lecture_id: lectureIdNum });
          students = res.students || [];
        } else {
          const res = await teacherAPI.getMyStudents({ lecture_id: lectureIdNum }).catch(() => ({ students: [] }));
          students = res.students || [];
        }
        const options = [
          { label: 'جميع الطلاب (الكل)', value: '' },
          ...students.map((s: any) => ({
            label: `${s.personalInfo?.firstNameAr || s.firstname || ''} ${s.personalInfo?.lastNameAr || s.lastname || ''}`.trim() || `طالب ${s.id}`,
            value: String(s.id),
          })),
        ];
        setStudentList(options);
        setStudent('');
      } catch (err) {
        console.error('Error loading students:', err);
      }
    }
    loadStudents();
  }, [halqa, isTeacher]);

  const totalSessions = attendanceData.total || (attendanceData.present + attendanceData.late + attendanceData.absent + attendanceData.excused);
  const presentPct = totalSessions > 0 ? Math.round((attendanceData.present / totalSessions) * 100) : 0;
  const latePct = totalSessions > 0 ? Math.round((attendanceData.late / totalSessions) * 100) : 0;
  const absentPct = totalSessions > 0 ? Math.round((attendanceData.absent / totalSessions) * 100) : 0;

  // SVG Donut Chart calculations
  const radius = 80;
  const circumference = 2 * Math.PI * radius;
  const strokeWidth = 24;

  const presentOffset = circumference - (presentPct / 100) * circumference;
  const lateOffset = circumference - (latePct / 100) * circumference;
  const absentOffset = circumference - (absentPct / 100) * circumference;

  const handleShowStats = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!halqa && !student) {
      alert('يرجى اختيار حلقة أو طالب على الأقل');
      return;
    }
    try {
      setLoading(true);
      const res = await reportsAPI.getAttendanceBreakdown({
        lecture_id: halqa ? Number(halqa) : undefined,
        student_id: student ? Number(student) : undefined,
        start_date: startDate,
        end_date: endDate,
      });

      setAttendanceData({
        present: res.present || 0,
        late: res.late || 0,
        absent: res.absent || 0,
        excused: res.excused || 0,
        total: res.total || 0,
      });
      setIsShowingStats(true);
    } catch (err) {
      console.error('Error fetching attendance stats:', err);
      alert('حدث خطأ أثناء جلب بيانات المواظبة');
    } finally {
      setLoading(false);
    }
  };

  const selectedHalqaLabel = halqaList.find((h) => h.value === halqa)?.label || 'الكل';
  const selectedStudentLabel = studentList.find((s) => s.value === student)?.label || 'الكل';

  return (
    <AppLayout title="إحصائيات المواظبة" breadcrumb="الشؤون الإدارية / الإحصاءات / إحصائيات المواظبة">
      <div className="max-w-5xl mx-auto space-y-6">
        {/* Banner Title */}
        <div className="bg-amber-500/85 text-white py-3.5 px-6 rounded-xl shadow-sm font-semibold text-sm flex items-center justify-between">
          <span>إحصائيات المواظبة</span>
          {isShowingStats && (
            <button
              onClick={() => setIsShowingStats(false)}
              className="flex items-center gap-1.5 hover:text-amber-100 transition-colors cursor-pointer text-xs bg-white/20 px-3 py-1.5 rounded-lg"
            >
              <ArrowRight size={14} />
              العودة للنموذج
            </button>
          )}
        </div>

        {!isShowingStats ? (
          /* ─── FORM VIEW ─── */
          <div className="bg-white rounded-3xl border border-gray-100 shadow-sm p-8 sm:p-12">
            <form onSubmit={handleShowStats} className="max-w-2xl mx-auto space-y-8">
              <div className="space-y-6">
                <Select
                  label="الحلقة *"
                  value={halqa}
                  onChange={(e) => setHalqa(e.target.value)}
                  options={halqaList}
                />

                <Select
                  label="الطالب (اختياري)"
                  value={student}
                  onChange={(e) => setStudent(e.target.value)}
                  options={studentList}
                />

                <div className="grid grid-cols-1 sm:grid-cols-2 gap-6">
                  <Input
                    label="تاريخ البداية *"
                    type="date"
                    value={startDate}
                    onChange={(e) => setStartDate(e.target.value)}
                  />
                  <Input
                    label="تاريخ النهاية *"
                    type="date"
                    value={endDate}
                    onChange={(e) => setEndDate(e.target.value)}
                  />
                </div>
              </div>

              <div className="pt-4 flex justify-center">
                <Button type="submit" size="lg" disabled={loading} className="px-12 rounded-xl text-base shadow-emerald-500/30 shadow-lg">
                  {loading ? <Loader2 className="w-5 h-5 animate-spin" /> : 'عرض الإحصائيات'}
                </Button>
              </div>
            </form>
          </div>
        ) : (
          /* ─── CHART VIEW ─── */
          <div className="bg-white rounded-3xl border border-gray-100 shadow-sm p-8 sm:p-12 space-y-12">
            {/* Header Info */}
            <div className="flex flex-wrap items-center justify-center gap-x-8 gap-y-3 text-sm font-semibold text-gray-700 bg-gray-50/50 p-4 rounded-2xl border border-gray-100">
              <span>الطالب: <span className="text-emerald-600">{selectedStudentLabel}</span></span>
              <span className="text-gray-300">|</span>
              <span>الحلقة: <span className="text-emerald-600">{selectedHalqaLabel}</span></span>
              <span className="text-gray-300">|</span>
              <span>من: <span className="text-emerald-600">{startDate}</span></span>
              <span className="text-gray-300">|</span>
              <span>إلى: <span className="text-emerald-600">{endDate}</span></span>
            </div>

            {/* Chart Section */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-12 items-center max-w-4xl mx-auto">
              {/* Donut Chart */}
              <div className="relative flex justify-center items-center">
                <svg width="240" height="240" viewBox="0 0 200 200" className="transform -rotate-90">
                  <circle cx="100" cy="100" r={radius} fill="none" stroke="#f3f4f6" strokeWidth={strokeWidth} />
                  
                  {/* Absent Segment */}
                  <circle
                    cx="100" cy="100" r={radius} fill="none" stroke="#ef4444" strokeWidth={strokeWidth}
                    style={{ strokeDashoffset: absentOffset, strokeDasharray: circumference, transformOrigin: 'center', transform: `rotate(${(presentPct + latePct) * 3.6}deg)` }}
                    className="transition-all duration-1000 ease-out"
                  />

                  {/* Late Segment */}
                  <circle
                    cx="100" cy="100" r={radius} fill="none" stroke="#f59e0b" strokeWidth={strokeWidth}
                    style={{ strokeDashoffset: lateOffset, strokeDasharray: circumference, transformOrigin: 'center', transform: `rotate(${presentPct * 3.6}deg)` }}
                    className="transition-all duration-1000 ease-out"
                  />

                  {/* Present Segment */}
                  <circle
                    cx="100" cy="100" r={radius} fill="none" stroke="#10b981" strokeWidth={strokeWidth}
                    strokeDasharray={circumference} strokeDashoffset={presentOffset}
                    className="transition-all duration-1000 ease-out"
                  />
                </svg>

                {/* Center Label */}
                <div className="absolute inset-0 flex flex-col items-center justify-center pointer-events-none">
                  <Users size={28} className="text-emerald-500 mb-1" />
                  <span className="text-3xl font-black text-gray-800">{presentPct}%</span>
                  <span className="text-xs font-semibold text-gray-500 uppercase tracking-widest mt-1">نسبة الحضور</span>
                </div>
              </div>

              {/* Data Summary Stats */}
              <div className="space-y-6 bg-gray-50/50 p-6 sm:p-8 rounded-3xl border border-gray-100">
                <h2 className="text-xl font-bold text-gray-800 mb-6">ملخص المواظبة</h2>

                {/* Present stat */}
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <div className="w-12 h-12 rounded-xl bg-emerald-100 flex items-center justify-center">
                      <div className="w-3 h-3 rounded-full bg-emerald-500"></div>
                    </div>
                    <div>
                      <p className="text-sm font-bold text-gray-800">حضور</p>
                      <p className="text-xs text-gray-500">طالب ملتزم بالحضور</p>
                    </div>
                  </div>
                  <div className="text-right">
                    <p className="text-xl font-black text-emerald-600">{attendanceData.present}</p>
                    <p className="text-xs font-bold text-gray-400">{presentPct}%</p>
                  </div>
                </div>

                {/* Late stat */}
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <div className="w-12 h-12 rounded-xl bg-amber-100 flex items-center justify-center">
                      <div className="w-3 h-3 rounded-full bg-amber-500"></div>
                    </div>
                    <div>
                      <p className="text-sm font-bold text-gray-800">تأخر</p>
                      <p className="text-xs text-gray-500">تأخر عن موعد الحلقة</p>
                    </div>
                  </div>
                  <div className="text-right">
                    <p className="text-xl font-black text-amber-600">{attendanceData.late}</p>
                    <p className="text-xs font-bold text-gray-400">{latePct}%</p>
                  </div>
                </div>

                {/* Absent stat */}
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <div className="w-12 h-12 rounded-xl bg-red-100 flex items-center justify-center">
                      <div className="w-3 h-3 rounded-full bg-red-500"></div>
                    </div>
                    <div>
                      <p className="text-sm font-bold text-gray-800">غياب</p>
                      <p className="text-xs text-gray-500">غياب عن الحلقة</p>
                    </div>
                  </div>
                  <div className="text-right">
                    <p className="text-xl font-black text-red-600">{attendanceData.absent}</p>
                    <p className="text-xs font-bold text-gray-400">{absentPct}%</p>
                  </div>
                </div>

                {/* Total */}
                <div className="pt-4 mt-4 border-t border-gray-200 flex justify-between items-center text-sm font-bold text-gray-600">
                  <span>إجمالي الجلسات المسجلة:</span>
                  <span>{totalSessions}</span>
                </div>
              </div>
            </div>
          </div>
        )}
      </div>
    </AppLayout>
  );
}
"""
write_file("app/statistics/attendance/page.tsx", stat_attendance_page)

# ==========================================
# 6. Update app/statistics/halqa/page.tsx
# ==========================================
stat_halqa_page = """'use client';

import React, { useState, useEffect } from 'react';
import { AppLayout } from '@/components/layout/AppLayout';
import { Select } from '@/components/ui/Select';
import { Input } from '@/components/ui/Input';
import { Button } from '@/components/ui/Button';
import { ArrowRight, Loader2 } from 'lucide-react';
import { useAuthStore } from '@/store/authStore';
import teacherAPI from '@/app/API/teacher';
import lecturesAPI from '@/app/API/lectures';
import reportsAPI from '@/app/API/reports';

export default function HalqaStatsPage() {
  const user = useAuthStore((s) => s.user);
  const isTeacher = user?.role === 'TEACHER';

  const [halqaList, setHalqaList] = useState<{ label: string; value: string }[]>([
    { label: 'اختر الحلقة', value: '' },
  ]);

  const [isShowingStats, setIsShowingStats] = useState(false);
  const [loading, setLoading] = useState(false);
  const [halqa, setHalqa] = useState('');
  const [startDate, setStartDate] = useState('2026-01-01');
  const [endDate, setEndDate] = useState(new Date().toISOString().split('T')[0]);

  const [chartData, setChartData] = useState<{ student: string; pages: number; color: string }[]>([]);

  // Load teacher's assigned lectures (episodes)
  useEffect(() => {
    async function loadLectures() {
      try {
        let lectures: any[] = [];
        if (isTeacher) {
          lectures = await teacherAPI.getMyLectures();
        } else {
          lectures = await lecturesAPI.getAllLectures();
        }
        const options = [
          { label: 'اختر الحلقة', value: '' },
          ...lectures.map((l: any) => ({
            label: l.lecture_name_ar || `حلقة ${l.lecture_id || l.id}`,
            value: String(l.lecture_id || l.id),
          })),
        ];
        setHalqaList(options);
      } catch (err) {
        console.error('Error loading lectures:', err);
      }
    }
    loadLectures();
  }, [isTeacher]);

  const maxChartValue = Math.max(10, ...(chartData.map((d) => d.pages) || [0])) + 5;

  const handleShowStats = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!halqa) {
      alert('يرجى اختيار الحلقة');
      return;
    }
    try {
      setLoading(true);
      const res = await reportsAPI.getHalqaBreakdown({
        lecture_id: Number(halqa),
        start_date: startDate,
        end_date: endDate,
      });

      const formatted = (res || []).map((item) => ({
        student: item.student,
        pages: item.pages || 0,
        color: 'bg-emerald-400',
      }));
      setChartData(formatted);
      setIsShowingStats(true);
    } catch (err) {
      console.error('Error fetching halqa stats:', err);
      alert('حدث خطأ أثناء جلب إحصائيات الحلقة');
    } finally {
      setLoading(false);
    }
  };

  const selectedHalqaLabel = halqaList.find((h) => h.value === halqa)?.label || halqa;

  return (
    <AppLayout title="إحصائيات الحلقة" breadcrumb="الشؤون الإدارية / الإحصاءات / إحصائيات الحلقة">
      <div className="max-w-5xl mx-auto space-y-6">
        {/* Banner Title */}
        <div className="bg-amber-500/85 text-white py-3.5 px-6 rounded-xl shadow-sm font-semibold text-sm flex items-center justify-between">
          <span>إحصائيات الحلقة</span>
          {isShowingStats && (
            <button
              onClick={() => setIsShowingStats(false)}
              className="flex items-center gap-1.5 hover:text-amber-100 transition-colors cursor-pointer text-xs bg-white/20 px-3 py-1.5 rounded-lg"
            >
              <ArrowRight size={14} />
              العودة للنموذج
            </button>
          )}
        </div>

        {!isShowingStats ? (
          /* ─── FORM VIEW ─── */
          <div className="bg-white rounded-3xl border border-gray-100 shadow-sm p-8 sm:p-12">
            <form onSubmit={handleShowStats} className="max-w-2xl mx-auto space-y-8">
              <div className="space-y-6">
                <Select
                  label="الحلقة *"
                  value={halqa}
                  onChange={(e) => setHalqa(e.target.value)}
                  options={halqaList}
                />

                <div className="grid grid-cols-1 sm:grid-cols-2 gap-6">
                  <Input
                    label="تاريخ البداية *"
                    type="date"
                    value={startDate}
                    onChange={(e) => setStartDate(e.target.value)}
                  />
                  <Input
                    label="تاريخ النهاية *"
                    type="date"
                    value={endDate}
                    onChange={(e) => setEndDate(e.target.value)}
                  />
                </div>
              </div>

              <div className="pt-4 flex justify-center">
                <Button type="submit" size="lg" disabled={loading} className="px-12 rounded-xl text-base shadow-emerald-500/30 shadow-lg">
                  {loading ? <Loader2 className="w-5 h-5 animate-spin" /> : 'عرض الإحصائيات'}
                </Button>
              </div>
            </form>
          </div>
        ) : (
          /* ─── CHART VIEW ─── */
          <div className="bg-white rounded-3xl border border-gray-100 shadow-sm p-8 sm:p-12 space-y-12">
            {/* Header Info */}
            <div className="flex flex-wrap items-center justify-center gap-x-8 gap-y-3 text-sm font-semibold text-gray-700 bg-gray-50/50 p-4 rounded-2xl border border-gray-100">
              <span>الحلقة: <span className="text-emerald-600">{selectedHalqaLabel}</span></span>
              <span className="text-gray-300">|</span>
              <span>من: <span className="text-emerald-600">{startDate}</span></span>
              <span className="text-gray-300">|</span>
              <span>إلى: <span className="text-emerald-600">{endDate}</span></span>
            </div>

            {/* Chart Section */}
            <div className="space-y-10">
              <h2 className="text-center text-xl font-bold text-gray-800">
                عدد الصفحات المحفوظة لكل طالب
              </h2>

              {chartData.length === 0 ? (
                <div className="p-8 text-center text-sm text-gray-500">لا يوجد طلاب أو إنجازات مسجلة في هذه الحلقة خلال الفترة المحددة</div>
              ) : (
                <div className="relative h-80 max-w-4xl mx-auto flex items-end justify-around pb-8 border-b-2 border-gray-100 pt-10 px-4">
                  {/* Y-axis labels */}
                  <div className="absolute left-0 top-0 bottom-8 flex flex-col justify-between text-xs text-gray-400 font-medium pr-4 border-r-2 border-gray-100 min-h-[300px] pb-4">
                    <span>{Math.round(maxChartValue)}</span>
                    <span>{Math.round(maxChartValue * 0.8)}</span>
                    <span>{Math.round(maxChartValue * 0.6)}</span>
                    <span>{Math.round(maxChartValue * 0.4)}</span>
                    <span>{Math.round(maxChartValue * 0.2)}</span>
                    <span>0</span>
                  </div>

                  {/* Bars */}
                  {chartData.map((item, index) => {
                    const heightPercent = (item.pages / maxChartValue) * 100;
                    return (
                      <div key={index} className="h-full flex flex-col justify-end items-center gap-3 w-1/4 group relative">
                        {/* Tooltip on hover */}
                        <div className="absolute top-0 -translate-y-full opacity-0 group-hover:opacity-100 transition-opacity bg-gray-800 text-white text-xs font-bold py-1.5 px-3 rounded-lg pointer-events-none z-10 whitespace-nowrap shadow-lg mb-2">
                          {item.student}: {item.pages} صفحة
                          <div className="absolute -bottom-1 left-1/2 -translate-x-1/2 w-2 h-2 bg-gray-800 rotate-45"></div>
                        </div>

                        {/* The Bar */}
                        <div
                          className={`w-full max-w-[40px] sm:max-w-[50px] rounded-t-md ${item.color} transition-all duration-700 ease-out shadow-sm group-hover:brightness-110 cursor-pointer relative z-0`}
                          style={{ height: `${heightPercent}%` }}
                        ></div>

                        {/* X-axis label (Student Name) */}
                        <span className="text-xs sm:text-sm font-semibold text-gray-600 absolute -bottom-8 whitespace-nowrap text-center">
                          {item.student}
                        </span>
                      </div>
                    );
                  })}
                </div>
              )}
            </div>
          </div>
        )}
      </div>
    </AppLayout>
  );
}
"""
write_file("app/statistics/halqa/page.tsx", stat_halqa_page)

# ==========================================
# 7. Update app/statistics/progress/page.tsx
# ==========================================
stat_progress_page = """'use client';

import React, { useState, useEffect } from 'react';
import { AppLayout } from '@/components/layout/AppLayout';
import { Select } from '@/components/ui/Select';
import { Input } from '@/components/ui/Input';
import { Button } from '@/components/ui/Button';
import { ArrowRight, Loader2 } from 'lucide-react';
import { useAuthStore } from '@/store/authStore';
import teacherAPI from '@/app/API/teacher';
import lecturesAPI from '@/app/API/lectures';
import reportsAPI from '@/app/API/reports';

export default function ProgressStatsPage() {
  const user = useAuthStore((s) => s.user);
  const isTeacher = user?.role === 'TEACHER';

  const [halqaList, setHalqaList] = useState<{ label: string; value: string }[]>([
    { label: 'اختر الحلقة', value: '' },
  ]);
  const [studentList, setStudentList] = useState<{ label: string; value: string }[]>([
    { label: 'اختر الطالب', value: '' },
  ]);

  const [isShowingStats, setIsShowingStats] = useState(false);
  const [loading, setLoading] = useState(false);
  const [halqa, setHalqa] = useState('');
  const [student, setStudent] = useState('');
  const [startDate, setStartDate] = useState('2026-01-01');
  const [endDate, setEndDate] = useState(new Date().toISOString().split('T')[0]);

  const [chartData, setChartData] = useState<
    { date: string; memorization: number; minorRev: number; majorRev: number }[]
  >([]);

  // Load teacher's assigned lectures (episodes)
  useEffect(() => {
    async function loadLectures() {
      try {
        let lectures: any[] = [];
        if (isTeacher) {
          lectures = await teacherAPI.getMyLectures();
        } else {
          lectures = await lecturesAPI.getAllLectures();
        }
        const options = [
          { label: 'اختر الحلقة', value: '' },
          ...lectures.map((l: any) => ({
            label: l.lecture_name_ar || `حلقة ${l.lecture_id || l.id}`,
            value: String(l.lecture_id || l.id),
          })),
        ];
        setHalqaList(options);
      } catch (err) {
        console.error('Error loading lectures:', err);
      }
    }
    loadLectures();
  }, [isTeacher]);

  // Load students for the selected halqa
  useEffect(() => {
    async function loadStudents() {
      try {
        let students: any[] = [];
        const lectureIdNum = halqa ? Number(halqa) : undefined;
        if (isTeacher) {
          const res = await teacherAPI.getMyStudents({ lecture_id: lectureIdNum });
          students = res.students || [];
        } else {
          const res = await teacherAPI.getMyStudents({ lecture_id: lectureIdNum }).catch(() => ({ students: [] }));
          students = res.students || [];
        }
        const options = [
          { label: 'اختر الطالب', value: '' },
          ...students.map((s: any) => ({
            label: `${s.personalInfo?.firstNameAr || s.firstname || ''} ${s.personalInfo?.lastNameAr || s.lastname || ''}`.trim() || `طالب ${s.id}`,
            value: String(s.id),
          })),
        ];
        setStudentList(options);
        setStudent('');
      } catch (err) {
        console.error('Error loading students:', err);
      }
    }
    loadStudents();
  }, [halqa, isTeacher]);

  const maxVal = Math.max(10, ...(chartData.flatMap((d) => [d.memorization, d.minorRev, d.majorRev]) || [0]));
  const maxChartValue = Math.ceil(maxVal * 1.2);

  const handleShowStats = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!student) {
      alert('يرجى اختيار الطالب');
      return;
    }
    try {
      setLoading(true);
      const res = await reportsAPI.getProgressTimeline({
        student_id: Number(student),
        start_date: startDate,
        end_date: endDate,
      });

      setChartData(res || []);
      setIsShowingStats(true);
    } catch (err) {
      console.error('Error fetching progress stats:', err);
      alert('حدث خطأ أثناء جلب مسار التطور');
    } finally {
      setLoading(false);
    }
  };

  const SVG_WIDTH = 800;
  const SVG_HEIGHT = 300;
  const PADDING_X = 40;
  const PADDING_Y = 20;

  const getX = (index: number) => {
    if (chartData.length <= 1) return SVG_WIDTH / 2;
    return PADDING_X + (index * (SVG_WIDTH - PADDING_X * 2)) / (chartData.length - 1);
  };

  const getY = (value: number) =>
    SVG_HEIGHT - PADDING_Y - (value / maxChartValue) * (SVG_HEIGHT - PADDING_Y * 2);

  const generatePath = (key: 'memorization' | 'minorRev' | 'majorRev') => {
    if (chartData.length === 0) return '';
    return chartData
      .map((d, i) => {
        const x = getX(i);
        const y = getY(d[key]);
        return `${i === 0 ? 'M' : 'L'} ${x} ${y}`;
      })
      .join(' ');
  };

  const selectedHalqaLabel = halqaList.find((h) => h.value === halqa)?.label || 'الكل';
  const selectedStudentLabel = studentList.find((s) => s.value === student)?.label || student;

  return (
    <AppLayout title="منحنى تطور الإنجاز" breadcrumb="الشؤون الإدارية / الإحصاءات / منحنى تطور الإنجاز">
      <div className="max-w-5xl mx-auto space-y-6">
        {/* Banner Title */}
        <div className="bg-amber-500/85 text-white py-3.5 px-6 rounded-xl shadow-sm font-semibold text-sm flex items-center justify-between">
          <span>منحنى تطور الإنجاز</span>
          {isShowingStats && (
            <button
              onClick={() => setIsShowingStats(false)}
              className="flex items-center gap-1.5 hover:text-amber-100 transition-colors cursor-pointer text-xs bg-white/20 px-3 py-1.5 rounded-lg"
            >
              <ArrowRight size={14} />
              العودة للنموذج
            </button>
          )}
        </div>

        {!isShowingStats ? (
          /* ─── FORM VIEW ─── */
          <div className="bg-white rounded-3xl border border-gray-100 shadow-sm p-8 sm:p-12">
            <form onSubmit={handleShowStats} className="max-w-2xl mx-auto space-y-8">
              <div className="space-y-6">
                <Select
                  label="الحلقة (اختياري للفلترة)"
                  value={halqa}
                  onChange={(e) => setHalqa(e.target.value)}
                  options={halqaList}
                />

                <Select
                  label="الطالب *"
                  value={student}
                  onChange={(e) => setStudent(e.target.value)}
                  options={studentList}
                />

                <div className="grid grid-cols-1 sm:grid-cols-2 gap-6">
                  <Input
                    label="تاريخ البداية *"
                    type="date"
                    value={startDate}
                    onChange={(e) => setStartDate(e.target.value)}
                  />
                  <Input
                    label="تاريخ النهاية *"
                    type="date"
                    value={endDate}
                    onChange={(e) => setEndDate(e.target.value)}
                  />
                </div>
              </div>

              <div className="pt-4 flex justify-center">
                <Button type="submit" size="lg" disabled={loading} className="px-12 rounded-xl text-base shadow-emerald-500/30 shadow-lg">
                  {loading ? <Loader2 className="w-5 h-5 animate-spin" /> : 'عرض الإحصائيات'}
                </Button>
              </div>
            </form>
          </div>
        ) : (
          /* ─── CHART VIEW ─── */
          <div className="bg-white rounded-3xl border border-gray-100 shadow-sm p-8 sm:p-12 space-y-12">
            {/* Header Info */}
            <div className="flex flex-wrap items-center justify-center gap-x-8 gap-y-3 text-sm font-semibold text-gray-700 bg-gray-50/50 p-4 rounded-2xl border border-gray-100">
              <span>الطالب: <span className="text-emerald-600">{selectedStudentLabel}</span></span>
              <span className="text-gray-300">|</span>
              <span>الحلقة: <span className="text-emerald-600">{selectedHalqaLabel}</span></span>
              <span className="text-gray-300">|</span>
              <span>من: <span className="text-emerald-600">{startDate}</span></span>
              <span className="text-gray-300">|</span>
              <span>إلى: <span className="text-emerald-600">{endDate}</span></span>
            </div>

            {/* Chart Section */}
            <div className="space-y-10">
              <div className="text-center space-y-3">
                <h2 className="text-xl font-bold text-gray-800">
                  منحنى تطور الإنجاز
                </h2>

                {/* Legend */}
                <div className="flex flex-wrap items-center justify-center gap-6">
                  <div className="flex items-center gap-2">
                    <span className="w-6 h-0.5 bg-emerald-400 relative">
                      <span className="absolute w-2 h-2 rounded-full bg-emerald-400 top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2"></span>
                    </span>
                    <span className="text-xs font-semibold text-gray-600">حفظ</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <span className="w-6 h-0.5 bg-amber-400 relative">
                      <span className="absolute w-2 h-2 rounded-full bg-amber-400 top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2"></span>
                    </span>
                    <span className="text-xs font-semibold text-gray-600">مراجعة صغرى</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <span className="w-6 h-0.5 bg-blue-400 relative">
                      <span className="absolute w-2 h-2 rounded-full bg-blue-400 top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2"></span>
                    </span>
                    <span className="text-xs font-semibold text-gray-600">مراجعة كبرى</span>
                  </div>
                </div>
              </div>

              {chartData.length === 0 ? (
                <div className="p-8 text-center text-sm text-gray-500">لا توجد إنجازات مسجلة لهذا الطالب خلال الفترة المحددة</div>
              ) : (
                <div className="relative w-full overflow-hidden flex pb-6 border-b-2 border-gray-100">
                  {/* Y-axis labels */}
                  <div className="flex flex-col justify-between text-xs text-gray-400 font-medium pr-4 border-r-2 border-gray-100 min-h-[300px] shrink-0 pb-4">
                    <span>{maxChartValue}</span>
                    <span>{Math.round(maxChartValue * 0.8)}</span>
                    <span>{Math.round(maxChartValue * 0.6)}</span>
                    <span>{Math.round(maxChartValue * 0.4)}</span>
                    <span>{Math.round(maxChartValue * 0.2)}</span>
                    <span>0</span>
                  </div>

                  {/* SVG Chart */}
                  <div className="relative w-full h-[300px]">
                    <svg viewBox={`0 0 ${SVG_WIDTH} ${SVG_HEIGHT}`} className="w-full h-full overflow-visible" preserveAspectRatio="none">
                      {/* Grid Lines (horizontal) */}
                      {[0, 0.2, 0.4, 0.6, 0.8, 1].map((ratio) => (
                        <line
                          key={ratio}
                          x1={0}
                          y1={getY(maxChartValue * ratio)}
                          x2={SVG_WIDTH}
                          y2={getY(maxChartValue * ratio)}
                          stroke="#f3f4f6"
                          strokeWidth="1"
                          strokeDasharray="4 4"
                        />
                      ))}

                      {/* Paths */}
                      <path d={generatePath('memorization')} fill="none" stroke="#34d399" strokeWidth="2.5" className="drop-shadow-sm" />
                      <path d={generatePath('minorRev')} fill="none" stroke="#fbbf24" strokeWidth="2.5" className="drop-shadow-sm" opacity="0.4" />
                      <path d={generatePath('majorRev')} fill="none" stroke="#60a5fa" strokeWidth="2.5" className="drop-shadow-sm" opacity="0.4" />

                      {/* Points */}
                      {chartData.map((d, i) => (
                        <g key={i}>
                          <circle cx={getX(i)} cy={getY(d.memorization)} r="4" fill="#34d399" className="hover:r-6 transition-all duration-300 cursor-pointer" />
                          <text x={getX(i)} y={getY(d.memorization) - 10} fontSize="12" fill="#34d399" textAnchor="middle" fontWeight="bold">
                            {d.memorization}
                          </text>

                          <circle cx={getX(i)} cy={getY(d.minorRev)} r="4" fill="#fbbf24" opacity="0.6" />
                          <circle cx={getX(i)} cy={getY(d.majorRev)} r="4" fill="#60a5fa" opacity="0.6" />
                        </g>
                      ))}
                    </svg>

                    {/* X-axis labels (Dates) */}
                    <div className="absolute left-0 right-0 -bottom-8 flex justify-between px-[40px]">
                      {chartData.map((d, i) => (
                        <span key={i} className="text-xs font-semibold text-gray-500 absolute -translate-x-1/2" style={{ left: `${(getX(i) / SVG_WIDTH) * 100}%` }}>
                          {d.date}
                        </span>
                      ))}
                    </div>
                  </div>
                </div>
              )}
            </div>
          </div>
        )}
      </div>
    </AppLayout>
  );
}
"""
write_file("app/statistics/progress/page.tsx", stat_progress_page)

print("ALL FRONTEND PATCHES COMPLETED SUCCESSFULLY!")
