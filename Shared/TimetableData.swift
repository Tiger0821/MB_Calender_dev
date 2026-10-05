/* The school's two-week timetable for each form, written by
   Tools/update_timetable.py from the published Prime Timetable. Don't edit
   the rows by hand: when the school republishes, run the script again.

   subject ~ day ~ start ~ end ~ staff ~ room
   Days 0-4 are Week 1 (the columns it numbers 1..5), 5-9 Week 2 (Mon..Fri).
   Cards the school has left off the grid are not lessons and are left out. */
enum TimetableData {
    /// The edition the rows were read from, and the day they were read.
    static let edition = "SY115-1 Secondary Sem 1 [Sept 1 Update]"
    static let readOn = "5 Oct 2026"

    /// The published timetable, and each form's own page on it, in the order
    /// setup offers them.
    static let publication = "3d9e5ee3-c15b-41f7-810c-0e16e6cafa92"
    static let forms: [(name: String, id: String)] = [
        ("11A", "5d3d7230-ad69-438a-9f7d-d5e238b3d94b"),
        ("11B", "6e80eda3-3061-41f2-9b6e-7cff2454c3dd"),
    ]

    static let rows: [String: String] = [
        "11A": #"""
G: Weekly Alignment~0~08:10~08:30~Benedikt Gottschlich~5F HS2
DP MAA HL~0~08:35~09:25~Emerson Michel~5F HS5
DP MAA SL~0~08:35~09:25~Adam Chiang~5F-Lab
DP MAI HL~0~08:35~09:25~Benedikt Gottschlich~5F HS3
DP MAA HL~0~09:25~10:10~Emerson Michel~5F HS5
DP MAA SL~0~09:25~10:10~Adam Chiang~5F-Lab
DP MAI HL~0~09:25~10:10~Benedikt Gottschlich~5F HS3
DP Chi A-1~0~10:20~11:05~Judy Wu 伍智梅~5F HS2
DP Chi B SL/HL~0~10:20~11:05~Evelyn Chang 張韻祥~5F HS3
DP Chi A-1~0~11:05~11:50~Judy Wu 伍智梅~5F HS2
DP Chi B SL/HL~0~11:05~11:50~Evelyn Chang 張韻祥~5F HS3
DP Chem~0~12:50~13:40~Maggie Gajewska~5F-Lab
DP Comp. Sc.~0~12:50~13:40~Michael Chiang~6F-DP VA Studio
DP ESS~0~12:50~13:40~Neil Hockin~5F HS2
DP Chem~0~13:40~14:25~Maggie Gajewska~5F-Lab
DP Comp. Sc.~0~13:40~14:25~Michael Chiang~6F-DP VA Studio
DP ESS~0~13:40~14:25~Neil Hockin~5F HS2
DP Bio~0~14:35~15:20~Sophia Lin~5F-Lab
DP Bus Man~0~14:35~15:20~Antony Chen~5F HS5
DP Physics~0~14:35~15:20~Benedikt Gottschlich~5F HS3
DP V. Arts~0~14:35~15:20~David Wang~6F-DP VA Studio
DP TOK-1~0~15:20~16:05~Michael Chiang~5F HS3
DP TOK-2~0~15:20~16:05~Harrison Hedges~5F HS5
DP Chi A-1 SL Revision~0~16:10~16:55~Judy Wu 伍智梅~5F HS3
G: Agency [EE, CAS, CC]~1~08:10~08:30~Curtis Quick~5F HS2
DP Econ~1~08:35~09:25~Michael Chiang~5F HS3
DP History~1~08:35~09:25~Neil Hockin~5F HS2
DP Psych~1~08:35~09:25~Andrew Wang~5F HS5
DP Econ~1~09:25~10:10~Michael Chiang~5F HS3
DP History~1~09:25~10:10~Neil Hockin~5F HS2
DP Psych~1~09:25~10:10~Andrew Wang~5F HS5
DP Eng A-2~1~10:20~11:05~Jillianne Burrow~5F HS4
DP Eng B-1~1~10:20~11:05~Curtis Quick~5F HS3
DP Eng A-2~1~11:05~11:50~Jillianne Burrow~5F HS4
DP Eng B-1~1~11:05~11:50~Curtis Quick~5F HS3
DP TOK-1~1~14:35~15:20~Michael Chiang~5F HS3
DP TOK-2~1~14:35~15:20~Harrison Hedges~5F HS2
Service Clubs~1~15:25~16:05~Claire Huang;Robert Chung;Evelyn Chang 張韻祥;Nancy Huang 黃聖雅~6F-DP VA Studio;6F DP Library;6F MYP Studio;5F CC;3F HS7 9B;3F HS6 9A;2F DP Chi Lib;5F-Lab
DP ESS SL Rrevision~1~16:10~16:55~Billy Leong~5F HS3
Guidance~2~08:10~08:30~Benedikt Gottschlich~5F HS2
DP MAA HL~2~08:35~09:25~Emerson Michel~5F HS5
DP MAA SL~2~08:35~09:25~Adam Chiang~5F-Lab
DP MAI HL~2~08:35~09:25~Benedikt Gottschlich~5F HS3
DP MAA HL~2~09:25~10:10~Emerson Michel~5F HS5
DP MAA SL~2~09:25~10:10~Adam Chiang~5F-Lab
DP MAI HL~2~09:25~10:10~Benedikt Gottschlich~5F HS3
DP Chi A-1~2~10:20~11:05~Judy Wu 伍智梅~3F HS6 9A
DP Chi B SL/HL~2~10:20~11:05~Evelyn Chang 張韻祥~5F HS3
DP Chi A-1~2~11:05~11:50~Judy Wu 伍智梅~3F HS6 9A
DP Chi B SL/HL~2~11:05~11:50~Evelyn Chang 張韻祥~5F HS3
DP Chem~2~12:50~13:40~Maggie Gajewska~5F-Lab
DP Comp. Sc.~2~12:50~13:40~Michael Chiang~6F-DP VA Studio
DP ESS~2~12:50~13:40~Billy Leong~5F HS2
DP Chem~2~13:40~14:25~Maggie Gajewska~5F-Lab
DP Comp. Sc.~2~13:40~14:25~Michael Chiang~6F-DP VA Studio
DP ESS~2~13:40~14:25~Billy Leong~5F HS2
DP Bio~2~14:35~15:20~Sophia Lin~5F-Lab
DP Bus Man~2~14:35~15:20~Antony Chen~5F HS5
DP Physics~2~14:35~15:20~Benedikt Gottschlich~5F HS3
DP V. Arts~2~14:35~15:20~David Wang~6F-DP VA Studio
DP Bio~2~15:20~16:05~Sophia Lin~5F-Lab
DP Physics~2~15:20~16:05~Benedikt Gottschlich~5F HS3
DP V. Arts~2~15:20~16:05~David Wang~6F-DP VA Studio
G: Agency [EE, CAS, CC]~3~08:10~08:30~Michael Chiang~5F HS2
DP Econ~3~08:35~09:25~Michael Chiang~5F HS3
DP History~3~08:35~09:25~Neil Hockin~5F HS2
DP Psych~3~08:35~09:25~Andrew Wang~5F HS5
DP Econ~3~09:25~10:10~Michael Chiang~5F HS3
DP History~3~09:25~10:10~Neil Hockin~5F HS2
DP Psych~3~09:25~10:10~Andrew Wang~5F HS5
DP Eng A-2~3~10:20~11:05~Jillianne Burrow~5F HS4
Eng Lit~3~10:20~11:05~Pete Williams~5F HS2
DP Eng A-2~3~11:05~11:50~Jillianne Burrow~5F HS4
Eng Lit~3~11:05~11:50~Pete Williams~5F HS2
DP Eng B-1~3~12:50~13:40~Curtis Quick~5F HS3
DP Eng B-1~3~13:40~14:25~Curtis Quick~5F HS3
DP TOK-1~3~14:35~15:20~Michael Chiang~5F HS3
DP TOK-2~3~14:35~15:20~Harrison Hedges~5F HS2
Academic Clubs~3~15:25~16:05~Judy Wu 伍智梅;Byron Dyck;Neil Hockin;Curtis Quick;David Huck;Emerson Michel;Maggie Gajewska;Michael Chiang;Adam Chiang;Benedikt Gottschlich;Sophia Lin~3F HS7 9B;3F HS6 9A;2F HS8 10A;5F-Lab;5F CC;6F DP Library;6F MYP Studio;6F-MPR;6F-DP VA Studio
DP Bio SL Revision~3~16:10~16:55~Sophia Lin~5F-Lab
DP Bus Man~3~16:10~16:55~Antony Chen~5F HS5
Guidance~4~08:10~08:30~Benedikt Gottschlich~5F HS2
DP MAA HL~4~08:35~09:25~Emerson Michel~5F HS5
DP MAA SL~4~08:35~09:25~Adam Chiang~5F HS4
DP MAI HL~4~08:35~09:25~Benedikt Gottschlich~5F HS3
DP MAA HL~4~09:25~10:10~Emerson Michel~5F HS5
DP MAA SL~4~09:25~10:10~Adam Chiang~5F HS4
DP MAI HL~4~09:25~10:10~Benedikt Gottschlich~5F HS3
DP Chi A-1~4~10:20~11:05~Judy Wu 伍智梅~5F HS2
DP Chi B SL/HL~4~10:20~11:05~Evelyn Chang 張韻祥~5F HS3
DP Chi A-1~4~11:05~11:50~Judy Wu 伍智梅~
DP Chi B SL/HL~4~11:05~11:50~Evelyn Chang 張韻祥~5F HS3
DP Eng B-1~4~12:50~13:40~Curtis Quick~5F HS3
DP Eng B-1~4~13:40~14:25~Curtis Quick~5F HS3
DP Bio~4~14:35~15:20~Sophia Lin~5F-Lab
DP Bus Man~4~14:35~15:20~Antony Chen~5F HS5
DP Physics~4~14:35~15:20~Benedikt Gottschlich~5F HS3
DP V. Arts~4~14:35~15:20~David Wang~6F-DP VA Studio
DP Bio~4~15:20~16:05~Sophia Lin~5F-Lab
DP Bus Man~4~15:20~16:05~Antony Chen~5F HS5
DP Physics~4~15:20~16:05~Benedikt Gottschlich~5F HS3
DP V. Arts~4~15:20~16:05~David Wang~6F-DP VA Studio
G: Weekly Alignment~5~08:10~08:30~Benedikt Gottschlich~5F HS2
DP MAA HL~5~08:35~09:25~Emerson Michel~5F HS5
DP MAA SL~5~08:35~09:25~Adam Chiang~5F-Lab
DP MAI HL~5~08:35~09:25~Benedikt Gottschlich~5F HS3
DP MAA HL~5~09:25~10:10~Emerson Michel~5F HS5
DP MAA SL~5~09:25~10:10~Adam Chiang~5F-Lab
DP MAI HL~5~09:25~10:10~Benedikt Gottschlich~5F HS3
DP Chi A-1~5~10:20~11:05~Judy Wu 伍智梅~5F HS2
DP Chi B SL/HL~5~10:20~11:05~Evelyn Chang 張韻祥~5F HS3
DP Chi A-1~5~11:05~11:50~Judy Wu 伍智梅~
DP Chi B SL/HL~5~11:05~11:50~Evelyn Chang 張韻祥~5F HS3
DP Bio~5~14:35~15:20~Sophia Lin~5F-Lab
DP Bus Man~5~14:35~15:20~Antony Chen~5F HS5
DP Physics~5~14:35~15:20~Benedikt Gottschlich~5F HS3
DP V. Arts~5~14:35~15:20~David Wang~
DP Bio~5~15:20~16:05~Sophia Lin~5F-Lab
DP Bus Man~5~15:20~16:05~Antony Chen~5F HS5
DP Physics~5~15:20~16:05~Benedikt Gottschlich~5F HS3
DP V. Arts~5~15:20~16:05~David Wang~
G: Agency [EE, CAS, CC]~6~08:10~08:30~Curtis Quick~5F HS2
DP Econ~6~08:35~09:25~Michael Chiang~5F HS3
DP History~6~08:35~09:25~Neil Hockin~5F HS2
DP Psych~6~08:35~09:25~Andrew Wang~5F HS5
DP Econ~6~09:25~10:10~Michael Chiang~5F HS3
DP History~6~09:25~10:10~Neil Hockin~5F HS2
DP Psych~6~09:25~10:10~Andrew Wang~5F HS5
DP Eng A-2~6~10:20~11:05~Jillianne Burrow~5F HS4
Eng Lit~6~10:20~11:05~Pete Williams~5F HS3
DP Eng A-2~6~11:05~11:50~Jillianne Burrow~5F HS4
Eng Lit~6~11:05~11:50~Pete Williams~5F HS3
DP Chem~6~12:50~13:40~Maggie Gajewska~5F-Lab
DP Comp. Sc.~6~12:50~13:40~Michael Chiang~6F-DP VA Studio
DP ESS~6~12:50~13:40~Billy Leong~5F HS2
DP Chem~6~13:40~14:25~Maggie Gajewska~5F-Lab
DP Comp. Sc.~6~13:40~14:25~Michael Chiang~6F-DP VA Studio
DP ESS~6~13:40~14:25~Billy Leong~5F HS2
DP Chi A-1 SL Revision~6~14:35~15:20~Judy Wu 伍智梅~5F HS3
Service Clubs~6~15:25~16:05~Billy Leong;Harrison Hedges;Jeremy Yeung;David Wang;Chelia Lei 雷靜宜;Jun-Wei Lee 李峻瑋;Claire Huang~6F-DP VA Studio;6F DP Library;6F MYP Studio;5F CC;3F HS7 9B;3F HS6 9A;2F DP Chi Lib;5F-Lab
Guidance~7~08:10~08:30~Benedikt Gottschlich~5F HS2
DP MAA HL~7~08:35~09:25~Emerson Michel~5F HS5
DP MAA SL~7~08:35~09:25~Adam Chiang~5F-Lab
DP MAI HL~7~08:35~09:25~Benedikt Gottschlich~5F HS3
DP MAA HL~7~09:25~10:10~Emerson Michel~5F HS5
DP MAA SL~7~09:25~10:10~Adam Chiang~5F-Lab
DP MAI HL~7~09:25~10:10~Benedikt Gottschlich~5F HS3
DP Chi A-1~7~10:20~11:05~Judy Wu 伍智梅~6F MYP Studio
DP Chi B SL/HL~7~10:20~11:05~Evelyn Chang 張韻祥~2F HS8 10A
DP Chi A-1~7~11:05~11:50~Judy Wu 伍智梅~6F MYP Studio
DP Chi B SL/HL~7~11:05~11:50~Evelyn Chang 張韻祥~2F HS8 10A
DP Eng B-1~7~12:50~13:40~Curtis Quick~5F HS3
DP Eng B-1~7~13:40~14:25~Curtis Quick~5F HS3
DP TOK-1~7~14:35~15:20~Michael Chiang~5F HS3
DP TOK-2~7~14:35~15:20~Harrison Hedges~5F HS5
DP Bio~7~15:20~16:05~Sophia Lin~5F-Lab
DP Physics~7~15:20~16:05~Benedikt Gottschlich~5F HS3
DP V. Arts~7~15:20~16:05~David Wang~6F-DP VA Studio
DP ESS SL Rrevision~7~16:10~16:55~Neil Hockin~5F HS3
G: Agency [EE, CAS, CC]~8~08:10~08:30~Michael Chiang~5F HS2
DP Econ~8~08:35~09:25~Michael Chiang~5F HS3
DP History~8~08:35~09:25~Neil Hockin~5F HS2
DP Psych~8~08:35~09:25~Andrew Wang~5F HS5
DP Econ~8~09:25~10:10~Michael Chiang~5F HS3
DP History~8~09:25~10:10~Neil Hockin~5F HS2
DP Psych~8~09:25~10:10~Andrew Wang~5F HS5
DP Eng A-2~8~10:20~11:05~Jillianne Burrow~5F HS4
DP Eng B-1~8~10:20~11:05~Curtis Quick~5F HS3
DP Eng A-2~8~11:05~11:50~Jillianne Burrow~5F HS4
DP Eng B-1~8~11:05~11:50~Curtis Quick~5F HS3
DP Chem~8~12:50~13:40~Maggie Gajewska~5F-Lab
DP Comp. Sc.~8~12:50~13:40~Michael Chiang~6F-DP VA Studio
DP ESS~8~12:50~13:40~Neil Hockin~5F HS2
DP Chem~8~13:40~14:25~Maggie Gajewska~5F-Lab
DP Comp. Sc.~8~13:40~14:25~Michael Chiang~6F-DP VA Studio
DP ESS~8~13:40~14:25~Neil Hockin~5F HS2
Academic Clubs~8~15:25~16:05~Judy Wu 伍智梅;Byron Dyck;Neil Hockin;Curtis Quick;David Huck;Emerson Michel;Maggie Gajewska;Michael Chiang;Adam Chiang;Benedikt Gottschlich;Sophia Lin~3F HS7 9B;3F HS6 9A;2F HS8 10A;5F-Lab;5F CC;6F DP Library;6F MYP Studio;6F-MPR;6F-DP VA Studio
DP Bio SL Revision~8~16:10~16:55~Sophia Lin~5F-Lab
DP Bus Man~8~16:10~16:55~Antony Chen~5F HS2
G: Agency [EE, CAS, CC]~9~08:10~08:30~~5F HS2
DP Econ~9~08:35~09:25~Michael Chiang~5F HS3
DP History~9~08:35~09:25~Neil Hockin~5F HS2
DP Psych~9~08:35~09:25~Andrew Wang~5F HS5
DP Econ~9~09:25~10:10~Michael Chiang~5F HS3
DP History~9~09:25~10:10~Neil Hockin~5F HS2
DP Psych~9~09:25~10:10~Andrew Wang~5F HS5
DP Eng A-2~9~10:20~11:05~Jillianne Burrow~5F HS4
Eng Lit~9~10:20~11:05~Pete Williams~5F HS2
DP Eng A-2~9~11:05~11:50~Jillianne Burrow~5F HS4
DP Chem~9~12:50~13:40~Maggie Gajewska~5F-Lab
DP Comp. Sc.~9~12:50~13:40~Michael Chiang~6F-DP VA Studio
DP ESS~9~12:50~13:40~Billy Leong~5F HS2
DP Chem~9~13:40~14:25~Maggie Gajewska~5F-Lab
DP Comp. Sc.~9~13:40~14:25~Michael Chiang~6F-DP VA Studio
DP ESS~9~13:40~14:25~Billy Leong~5F HS2
DP Bio~9~14:35~15:20~Sophia Lin~5F-Lab
DP Bus Man~9~14:35~15:20~Antony Chen~5F HS5
DP Physics~9~14:35~15:20~Benedikt Gottschlich~5F HS3
DP V. Arts~9~14:35~15:20~David Wang~6F-DP VA Studio
DP Bio~9~15:20~16:05~Sophia Lin~5F-Lab
DP Bus Man~9~15:20~16:05~Antony Chen~5F HS5
DP Physics~9~15:20~16:05~Benedikt Gottschlich~5F HS3
DP V. Arts~9~15:20~16:05~David Wang~6F-DP VA Studio
"""#,
        "11B": #"""
G: Agency [EE, CAS, CC]~0~08:10~08:30~Michael Chiang~5F HS3
DP MAA HL~0~08:35~09:25~Emerson Michel~5F HS5
DP MAA SL~0~08:35~09:25~Adam Chiang~5F-Lab
DP MAI HL~0~08:35~09:25~Benedikt Gottschlich~5F HS3
DP MAA HL~0~09:25~10:10~Emerson Michel~5F HS5
DP MAA SL~0~09:25~10:10~Adam Chiang~5F-Lab
DP MAI HL~0~09:25~10:10~Benedikt Gottschlich~5F HS3
DP Chi B SL/HL~0~10:20~11:05~Evelyn Chang 張韻祥~5F HS3
DP Eng B-2~0~10:20~11:05~David Huck~5F HS4
DP Chi B SL/HL~0~11:05~11:50~Evelyn Chang 張韻祥~5F HS3
DP Eng B-2~0~11:05~11:50~David Huck~5F HS4
DP Comp. Sc.~0~12:50~13:40~Michael Chiang~6F-DP VA Studio
DP ESS~0~12:50~13:40~Neil Hockin~5F HS2
DP Comp. Sc.~0~13:40~14:25~Michael Chiang~6F-DP VA Studio
DP ESS~0~13:40~14:25~Neil Hockin~5F HS2
DP Bio~0~14:35~15:20~Sophia Lin~5F-Lab
DP Bus Man~0~14:35~15:20~Antony Chen~5F HS5
DP Physics~0~14:35~15:20~Benedikt Gottschlich~5F HS3
DP V. Arts~0~14:35~15:20~David Wang~6F-DP VA Studio
DP TOK-1~0~15:20~16:05~Michael Chiang~5F HS3
DP TOK-2~0~15:20~16:05~Harrison Hedges~5F HS5
G: Weekly Alignment~1~08:10~08:30~Benedikt Gottschlich~5F HS3
DP Econ~1~08:35~09:25~Michael Chiang~5F HS3
DP History~1~08:35~09:25~Neil Hockin~5F HS2
DP Psych~1~08:35~09:25~Andrew Wang~5F HS5
DP Econ~1~09:25~10:10~Michael Chiang~5F HS3
DP History~1~09:25~10:10~Neil Hockin~5F HS2
DP Psych~1~09:25~10:10~Andrew Wang~5F HS5
DP Eng A-2~1~10:20~11:05~Jillianne Burrow~5F HS4
Eng Lit~1~10:20~11:05~Pete Williams~3F HS6 9A
DP Eng A-2~1~11:05~11:50~Jillianne Burrow~5F HS4
Eng Lit~1~11:05~11:50~Pete Williams~3F HS6 9A
DP Chem~1~12:50~13:40~Maggie Gajewska~5F-Lab
DP Chi A-2~1~12:50~13:40~Judy Wu 伍智梅~5F HS2
DP Chem~1~13:40~14:25~Maggie Gajewska~5F-Lab
DP Chi A-2~1~13:40~14:25~Judy Wu 伍智梅~5F HS2
DP TOK-1~1~14:35~15:20~Michael Chiang~5F HS3
DP TOK-2~1~14:35~15:20~Harrison Hedges~5F HS2
Service Clubs~1~15:25~16:05~Claire Huang;Robert Chung;Evelyn Chang 張韻祥;Nancy Huang 黃聖雅~6F-DP VA Studio;6F DP Library;6F MYP Studio;5F CC;3F HS7 9B;3F HS6 9A;2F DP Chi Lib;5F-Lab
DP ESS SL Rrevision~1~16:10~16:55~Billy Leong~5F HS3
G: Agency [EE, CAS, CC]~2~08:10~08:30~Andrew Wang;Jeremy Yeung~5F HS3
DP MAA HL~2~08:35~09:25~Emerson Michel~5F HS5
DP MAA SL~2~08:35~09:25~Adam Chiang~5F-Lab
DP MAI HL~2~08:35~09:25~Benedikt Gottschlich~5F HS3
DP MAA HL~2~09:25~10:10~Emerson Michel~5F HS5
DP MAA SL~2~09:25~10:10~Adam Chiang~5F-Lab
DP MAI HL~2~09:25~10:10~Benedikt Gottschlich~5F HS3
DP Chi B SL/HL~2~10:20~11:05~Evelyn Chang 張韻祥~5F HS3
DP Eng B-2~2~10:20~11:05~David Huck~2F HS8 10A
DP Chi B SL/HL~2~11:05~11:50~Evelyn Chang 張韻祥~5F HS3
DP Eng B-2~2~11:05~11:50~David Huck~2F HS8 10A
DP Comp. Sc.~2~12:50~13:40~Michael Chiang~6F-DP VA Studio
DP ESS~2~12:50~13:40~Billy Leong~5F HS2
DP Comp. Sc.~2~13:40~14:25~Michael Chiang~6F-DP VA Studio
DP ESS~2~13:40~14:25~Billy Leong~5F HS2
DP Bio~2~14:35~15:20~Sophia Lin~5F-Lab
DP Bus Man~2~14:35~15:20~Antony Chen~5F HS5
DP Physics~2~14:35~15:20~Benedikt Gottschlich~5F HS3
DP V. Arts~2~14:35~15:20~David Wang~6F-DP VA Studio
DP Bio~2~15:20~16:05~Sophia Lin~5F-Lab
DP Physics~2~15:20~16:05~Benedikt Gottschlich~5F HS3
DP V. Arts~2~15:20~16:05~David Wang~6F-DP VA Studio
DP Chi A-2 SL Revision~2~16:10~16:55~Judy Wu 伍智梅~5F HS3
Guidance~3~08:10~08:30~Benedikt Gottschlich~5F HS3
DP Econ~3~08:35~09:25~Michael Chiang~5F HS3
DP History~3~08:35~09:25~Neil Hockin~5F HS2
DP Psych~3~08:35~09:25~Andrew Wang~5F HS5
DP Econ~3~09:25~10:10~Michael Chiang~5F HS3
DP History~3~09:25~10:10~Neil Hockin~5F HS2
DP Psych~3~09:25~10:10~Andrew Wang~5F HS5
DP Eng A-2~3~10:20~11:05~Jillianne Burrow~5F HS4
DP Eng A-2~3~11:05~11:50~Jillianne Burrow~5F HS4
DP Chem~3~12:50~13:40~Maggie Gajewska~5F-Lab
DP Chi A-2~3~12:50~13:40~Judy Wu 伍智梅~5F HS2
DP Chem~3~13:40~14:25~Maggie Gajewska~5F-Lab
DP Chi A-2~3~13:40~14:25~Judy Wu 伍智梅~5F HS2
DP TOK-1~3~14:35~15:20~Michael Chiang~5F HS3
DP TOK-2~3~14:35~15:20~Harrison Hedges~5F HS2
Academic Clubs~3~15:25~16:05~Judy Wu 伍智梅;Byron Dyck;Neil Hockin;Curtis Quick;David Huck;Emerson Michel;Maggie Gajewska;Michael Chiang;Adam Chiang;Benedikt Gottschlich;Sophia Lin~3F HS7 9B;3F HS6 9A;2F HS8 10A;5F-Lab;5F CC;6F DP Library;6F MYP Studio;6F-MPR;6F-DP VA Studio
DP Bio SL Revision~3~16:10~16:55~Sophia Lin~5F-Lab
DP Bus Man~3~16:10~16:55~Antony Chen~5F HS5
G: Agency [EE, CAS, CC]~4~08:10~08:30~~5F HS3
DP MAA HL~4~08:35~09:25~Emerson Michel~5F HS5
DP MAA SL~4~08:35~09:25~Adam Chiang~5F HS4
DP MAI HL~4~08:35~09:25~Benedikt Gottschlich~5F HS3
DP MAA HL~4~09:25~10:10~Emerson Michel~5F HS5
DP MAA SL~4~09:25~10:10~Adam Chiang~5F HS4
DP MAI HL~4~09:25~10:10~Benedikt Gottschlich~5F HS3
DP Chi B SL/HL~4~10:20~11:05~Evelyn Chang 張韻祥~5F HS3
DP Eng B-2~4~10:20~11:05~David Huck~2F HS8 10A
DP Chi B SL/HL~4~11:05~11:50~Evelyn Chang 張韻祥~5F HS3
DP Eng B-2~4~11:05~11:50~David Huck~2F HS8 10A
DP Chem~4~12:50~13:40~Maggie Gajewska~5F-Lab
DP Chi A-2~4~12:50~13:40~Judy Wu 伍智梅~5F HS5
DP Chem~4~13:40~14:25~Maggie Gajewska~5F-Lab
DP Chi A-2~4~13:40~14:25~Judy Wu 伍智梅~5F HS5
DP Bio~4~14:35~15:20~Sophia Lin~5F-Lab
DP Bus Man~4~14:35~15:20~Antony Chen~5F HS5
DP Physics~4~14:35~15:20~Benedikt Gottschlich~5F HS3
DP V. Arts~4~14:35~15:20~David Wang~6F-DP VA Studio
DP Bio~4~15:20~16:05~Sophia Lin~5F-Lab
DP Bus Man~4~15:20~16:05~Antony Chen~5F HS5
DP Physics~4~15:20~16:05~Benedikt Gottschlich~5F HS3
DP V. Arts~4~15:20~16:05~David Wang~6F-DP VA Studio
G: Agency [EE, CAS, CC]~5~08:10~08:30~Michael Chiang~5F HS3
DP MAA HL~5~08:35~09:25~Emerson Michel~5F HS5
DP MAA SL~5~08:35~09:25~Adam Chiang~5F-Lab
DP MAI HL~5~08:35~09:25~Benedikt Gottschlich~5F HS3
DP MAA HL~5~09:25~10:10~Emerson Michel~5F HS5
DP MAA SL~5~09:25~10:10~Adam Chiang~5F-Lab
DP MAI HL~5~09:25~10:10~Benedikt Gottschlich~5F HS3
DP Chi B SL/HL~5~10:20~11:05~Evelyn Chang 張韻祥~5F HS3
DP Eng B-2~5~10:20~11:05~David Huck~1F HS9 10B
DP Chi B SL/HL~5~11:05~11:50~Evelyn Chang 張韻祥~5F HS3
DP Eng B-2~5~11:05~11:50~David Huck~1F HS9 10B
DP Chem~5~12:50~13:40~Maggie Gajewska~5F-Lab
DP Chi A-2~5~12:50~13:40~Judy Wu 伍智梅~5F HS4
DP Chem~5~13:40~14:25~Maggie Gajewska~5F-Lab
DP Chi A-2~5~13:40~14:25~Judy Wu 伍智梅~5F HS4
DP Bio~5~14:35~15:20~Sophia Lin~5F-Lab
DP Bus Man~5~14:35~15:20~Antony Chen~5F HS5
DP Physics~5~14:35~15:20~Benedikt Gottschlich~5F HS3
DP V. Arts~5~14:35~15:20~David Wang~
DP Bio~5~15:20~16:05~Sophia Lin~5F-Lab
DP Bus Man~5~15:20~16:05~Antony Chen~5F HS5
DP Physics~5~15:20~16:05~Benedikt Gottschlich~5F HS3
DP V. Arts~5~15:20~16:05~David Wang~
G: Weekly Alignment~6~08:10~08:30~Benedikt Gottschlich~5F HS3
DP Econ~6~08:35~09:25~Michael Chiang~5F HS3
DP History~6~08:35~09:25~Neil Hockin~5F HS2
DP Psych~6~08:35~09:25~Andrew Wang~5F HS5
DP Econ~6~09:25~10:10~Michael Chiang~5F HS3
DP History~6~09:25~10:10~Neil Hockin~5F HS2
DP Psych~6~09:25~10:10~Andrew Wang~5F HS5
DP Eng A-2~6~10:20~11:05~Jillianne Burrow~5F HS4
DP Eng A-2~6~11:05~11:50~Jillianne Burrow~5F HS4
DP Comp. Sc.~6~12:50~13:40~Michael Chiang~6F-DP VA Studio
DP ESS~6~12:50~13:40~Billy Leong~5F HS2
DP Comp. Sc.~6~13:40~14:25~Michael Chiang~6F-DP VA Studio
DP ESS~6~13:40~14:25~Billy Leong~5F HS2
Service Clubs~6~15:25~16:05~Billy Leong;Harrison Hedges;Jeremy Yeung;David Wang;Chelia Lei 雷靜宜;Jun-Wei Lee 李峻瑋;Claire Huang~6F-DP VA Studio;6F DP Library;6F MYP Studio;5F CC;3F HS7 9B;3F HS6 9A;2F DP Chi Lib;5F-Lab
G: Agency [EE, CAS, CC]~7~08:10~08:30~Andrew Wang;Jeremy Yeung~5F HS3
DP MAA HL~7~08:35~09:25~Emerson Michel~5F HS5
DP MAA SL~7~08:35~09:25~Adam Chiang~5F-Lab
DP MAI HL~7~08:35~09:25~Benedikt Gottschlich~5F HS3
DP MAA HL~7~09:25~10:10~Emerson Michel~5F HS5
DP MAA SL~7~09:25~10:10~Adam Chiang~5F-Lab
DP MAI HL~7~09:25~10:10~Benedikt Gottschlich~5F HS3
DP Chi B SL/HL~7~10:20~11:05~Evelyn Chang 張韻祥~2F HS8 10A
DP Eng B-2~7~10:20~11:05~David Huck~5F HS3
DP Chi B SL/HL~7~11:05~11:50~Evelyn Chang 張韻祥~2F HS8 10A
DP Eng B-2~7~11:05~11:50~David Huck~5F HS3
DP Chem~7~12:50~13:40~Maggie Gajewska~5F-Lab
DP Chi A-2~7~12:50~13:40~Judy Wu 伍智梅~5F HS2
DP Chem~7~13:40~14:25~Maggie Gajewska~5F-Lab
DP Chi A-2~7~13:40~14:25~Judy Wu 伍智梅~5F HS2
DP TOK-1~7~14:35~15:20~Michael Chiang~5F HS3
DP TOK-2~7~14:35~15:20~Harrison Hedges~5F HS5
DP Bio~7~15:20~16:05~Sophia Lin~5F-Lab
DP Physics~7~15:20~16:05~Benedikt Gottschlich~5F HS3
DP V. Arts~7~15:20~16:05~David Wang~6F-DP VA Studio
DP ESS SL Rrevision~7~16:10~16:55~Neil Hockin~5F HS3
Guidance~8~08:10~08:30~Benedikt Gottschlich~5F HS3
DP Econ~8~08:35~09:25~Michael Chiang~5F HS3
DP History~8~08:35~09:25~Neil Hockin~5F HS2
DP Psych~8~08:35~09:25~Andrew Wang~5F HS5
DP Econ~8~09:25~10:10~Michael Chiang~5F HS3
DP History~8~09:25~10:10~Neil Hockin~5F HS2
DP Psych~8~09:25~10:10~Andrew Wang~5F HS5
DP Eng A-2~8~10:20~11:05~Jillianne Burrow~5F HS4
Eng Lit~8~10:20~11:05~Pete Williams~5F HS2
DP Eng A-2~8~11:05~11:50~Jillianne Burrow~5F HS4
Eng Lit~8~11:05~11:50~Pete Williams~5F HS2
DP Comp. Sc.~8~12:50~13:40~Michael Chiang~6F-DP VA Studio
DP ESS~8~12:50~13:40~Neil Hockin~5F HS2
DP Comp. Sc.~8~13:40~14:25~Michael Chiang~6F-DP VA Studio
DP ESS~8~13:40~14:25~Neil Hockin~5F HS2
DP Chi A-2 SL Revision~8~14:35~15:20~Judy Wu 伍智梅~5F HS3
Academic Clubs~8~15:25~16:05~Judy Wu 伍智梅;Byron Dyck;Neil Hockin;Curtis Quick;David Huck;Emerson Michel;Maggie Gajewska;Michael Chiang;Adam Chiang;Benedikt Gottschlich;Sophia Lin~3F HS7 9B;3F HS6 9A;2F HS8 10A;5F-Lab;5F CC;6F DP Library;6F MYP Studio;6F-MPR;6F-DP VA Studio
DP Bio SL Revision~8~16:10~16:55~Sophia Lin~5F-Lab
DP Bus Man~8~16:10~16:55~Antony Chen~5F HS2
Guidance~9~08:10~08:30~Benedikt Gottschlich~5F HS3
DP Econ~9~08:35~09:25~Michael Chiang~5F HS3
DP History~9~08:35~09:25~Neil Hockin~5F HS2
DP Psych~9~08:35~09:25~Andrew Wang~5F HS5
DP Econ~9~09:25~10:10~Michael Chiang~5F HS3
DP History~9~09:25~10:10~Neil Hockin~5F HS2
DP Psych~9~09:25~10:10~Andrew Wang~5F HS5
DP Eng A-2~9~10:20~11:05~Jillianne Burrow~5F HS4
DP Eng A-2~9~11:05~11:50~Jillianne Burrow~5F HS4
Eng Lit~9~11:05~11:50~Pete Williams~5F HS2
DP Comp. Sc.~9~12:50~13:40~Michael Chiang~6F-DP VA Studio
DP ESS~9~12:50~13:40~Billy Leong~5F HS2
DP Comp. Sc.~9~13:40~14:25~Michael Chiang~6F-DP VA Studio
DP ESS~9~13:40~14:25~Billy Leong~5F HS2
DP Bio~9~14:35~15:20~Sophia Lin~5F-Lab
DP Bus Man~9~14:35~15:20~Antony Chen~5F HS5
DP Physics~9~14:35~15:20~Benedikt Gottschlich~5F HS3
DP V. Arts~9~14:35~15:20~David Wang~6F-DP VA Studio
DP Bio~9~15:20~16:05~Sophia Lin~5F-Lab
DP Bus Man~9~15:20~16:05~Antony Chen~5F HS5
DP Physics~9~15:20~16:05~Benedikt Gottschlich~5F HS3
DP V. Arts~9~15:20~16:05~David Wang~6F-DP VA Studio
"""#,
    ]
}
