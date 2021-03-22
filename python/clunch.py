#!/usr/bin/python
# -*- coding: utf-8 -*-

from __future__ import print_function  # print python2
from datetime import datetime
from datetime import timedelta
from threading import Thread
import xml.etree.ElementTree as ET
import xml.dom.minidom
import urllib3
import locale
import json
import sys
import re

PY_VERSION = sys.version_info[0]

if PY_VERSION < 3:
    from Queue import Queue
elif PY_VERSION >= 3:
    from queue import Queue


RESTAURANTS = [["Expressen", '3d519481-1667-4cad-d2a3'],
               ["Kårrestaurangen", '21f31565-5c2b-4b47-d2a1'],
               ["Linsen", 'b672efaf-032a-4bb8-d2a5'],
               ["S.M.A.K", '3ac68e11-bcee-425e-d2a8'],
               ["J.A. Pripps", 'http://intern.chalmerskonferens.se/'
                'view/restaurant/j-a-pripps-pub-cafe/RSS%20Feed.rss']]


def main():
    locale.setlocale(locale.LC_ALL, 'sv_SE.utf-8')
    try:
        arg = int(sys.argv[1:][0]) - 1
        num_of_days = arg if arg >= 0 else 0
    except Exception:
        num_of_days = 0

    info = Style.style("[INFO]", "green", [])
    print(info, "Fetching data...")

    menus = get_menus(num_of_days)
    if not menus:
        print(info, 'INGEN DATA')
        exit(1)

    print_data(menus)


def get_menus(num_of_days):
    menus = dict()
    queue = build_queue()
    qsize = queue.qsize()
    http = urllib3.PoolManager(maxsize=qsize)

    for i in range(qsize):
        thread = Thread(target=get_menus_thread,
                        args=(queue, http, menus, num_of_days))
        thread.daemon = True
        thread.start()

    queue.join()
    http.clear()

    return menus


def build_queue():
    queue = Queue()
    num_of_restaurants = len(RESTAURANTS)

    for i in range(num_of_restaurants):
        queue.put(i)

    return queue


def get_menus_thread(queue, http, menus, num_of_days):
    while not queue.empty():
        i = queue.get()
        restaurant = RESTAURANTS[i][0]
        data = request_menu(i, http, num_of_days)

        if data is not None:
            if restaurant == 'J.A. Pripps':
                menu = parse_pripps_menu(data, num_of_days)
            else:
                menu = parse_menu(data)

            parse_data(menus, menu, i)

        queue.task_done()


def parse_menu(data):
    rawdata = json.loads(data)
    menu = []

    for i in rawdata:
        menu.append(format_date(i['startDate']))
        menu.append(i['displayNames'][0]['dishDisplayName'])

    return menu


def parse_pripps_menu(data, num_of_days):
    item = ET.fromstring(data).findall('channel/item')
    menu = []
    start_date, end_date = get_dates(num_of_days)

    for title in item:
        date = title.find("title").text[-10:]

        for description in title:
            for table in description:
                for tr in table:
                    for td in tr:
                        dish = tr.findall("td")[1].text

                        for b in td:
                            dish_type = b.text

                            if start_date <= date <= end_date:
                                append_data(menu,
                                            date,
                                            dish,
                                            dish_type)
    return menu


def parse_data(menus, data, restaurant):
    num_of_restaurants = len(RESTAURANTS)
    length = len(data)

    for i in range(0, length, 2):
        date = data[i]
        dish = data[i+1]

        if date in menus:
            menus[date][restaurant].append(dish)
        else:
            disharr = [[] for i in range(num_of_restaurants)]
            disharr[restaurant].append(dish)
            menus[date] = disharr


def request_menu(i, http, num_of_days):
    url = build_url(i, num_of_days)
    try:
        res = http.request(
            method='GET',
            url=url,
            preload_content=False,
            retries=urllib3.Retry(10),
            timeout=urllib3.Timeout(10))

        status_code = res.status

        if status_code == 200:
            return res.read()
        else:
            print("HTTP status code: %s" % status_code)
            print("URL: %s" % url)
            return None
    except Exception as e:
        print("Exception: %s" % e)
        return None


def build_url(i, num_of_days):
    restaurant = RESTAURANTS[i][0]

    if restaurant == 'J.A. Pripps':
        return RESTAURANTS[i][1]
    else:
        start_date, end_date = get_dates(num_of_days)

        return Api.url(
            RESTAURANTS[i][1],
            start_date,
            end_date)


def get_dates(num_of_days):
    today = datetime.today()
    start_date = today.strftime(Utils.format('Ymd'))
    end_date = (
        today + timedelta(days=num_of_days)).strftime(Utils.format('Ymd'))

    return start_date, end_date


def format_date(date):
    return datetime.strptime(
        date[:-3], Utils.format('mdYHMS')).strftime(Utils.format('Ymd'))


def append_data(menu, date, dish, dish_type):
    menu.append(date)
    menu.append(dish + Style.dim(" (" + dish_type + ")"))


def find_match(dish):
    match = re.search(
        r'\b' + Utils.decode('(köttbullar|meatballs)') + r'\b', dish, re.IGNORECASE)
    try:
        index = match.start()
        _len = (index + len(match.group(0)))
        return index, _len
    except AttributeError:
        return None, None


class Api:
    URL = \
        'http://carbonateapiprod.azurewebsites.net/' \
        'api/v1/mealprovidingunits/'

    @staticmethod
    def url(restaurant, start_date, end_date):
        return Api.URL + restaurant + \
            '-08d558129279/dishoccurrences?' \
            'startDate=' + start_date + \
            '&endDate=' + end_date


class Utils:
    @staticmethod
    def decode(string):
        return string.decode("utf-8") if PY_VERSION < 3 else string

    @staticmethod
    def format(arg):
        return {
            'Ymd': '%Y-%m-%d',
            'mdYHMS': '%m/%d/%Y %H:%M:%S'
        }[arg]


class Style:
    DEFAULT = '\033[0m'
    GREEN = '\033[92m'
    BLUE = '\033[94m'
    BOLD = "\033[1m"
    BLINK = '\33[5m'
    DIM = '\033[2m'

    @staticmethod
    def style(output, color, styles=[]):
        if color is not None:
            output = {
                'green': Style.GREEN + '%s',
                'blue': Style.BLUE + '%s',
            }[color] % output

        for style in styles:
            output = {
                'blink': Style.BLINK + '%s',
                'bold': Style.BOLD + '%s',
                'dim': Style.DIM + '%s'
            }[style] % output

        return output + Style.DEFAULT


# -----------------------------------------------------------------
# PRINT
# -----------------------------------------------------------------
def print_data(menus):
    # print menu
    for date in sorted(menus):
        print()
        day = datetime.strptime(date, Utils.format('Ymd')).strftime('%a')
        print(Style.style(day, 'green', ['bold']))
        # print restaurant
        for restaurant, menu in enumerate(menus[date]):
            print(Style.style(RESTAURANTS[restaurant][0], 'blue'))
            if not menu:
                print(Utils.decode('· ') +
                      Style.style('INGEN MENY', None, ['dim']))
            else:
                # print dish
                for dish in menu:
                    index, _len = find_match(dish)
                    # print dish
                    if index is None:
                        print(Utils.decode('· ') + dish)
                    # print match
                    else:
                        head = dish[0:index]
                        body = dish[index:_len]
                        tail = dish[_len:]
                        print(body)
                        print(
                            Utils.decode('· ') + head + Style.style(body, None, ['blink']) + tail)
    print()


if __name__ == "__main__":
    main()
